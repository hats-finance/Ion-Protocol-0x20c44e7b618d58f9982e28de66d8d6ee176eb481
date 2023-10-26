// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

// import { safeconsole as console } from "forge-std/safeconsole.sol";

import { IonPoolSharedSetup } from "../helpers/IonPoolSharedSetup.sol";
import { Liquidation } from "src/Liquidation.sol";
import { GemJoin } from "../../src/join/GemJoin.sol";
import { RoundedMath } from "../../src/math/RoundedMath.sol";
import { ReserveOracle } from "../../src/oracle/ReserveOracle.sol";
import { StEthReserveOracle } from "../../src/oracle/StEthReserveOracle.sol";
import "forge-std/console.sol";

contract MockStEthReserveOracle {
    uint256 public exchangeRate;

    function setExchangeRate(uint256 _exchangeRate) public {
        exchangeRate = _exchangeRate;
    }
    // @dev called by Liquidation.sol

    function getExchangeRate(uint256 ilkIndex) public returns (uint256) {
        return exchangeRate;
    }
}

contract LiquidationTest is IonPoolSharedSetup {
    using RoundedMath for uint256;

    uint256 constant WAD = 1e18;
    uint256 constant RAY = 1e27;

    uint32 constant ILK_COUNT = 8; // NOTE: Need to match with the ILK_COUNT in Liquidation.sol

    Liquidation public liquidation;
    GemJoin public stEthJoin;
    MockStEthReserveOracle public reserveOracle;

    uint8 public stEthIndex;

    address immutable keeper1 = vm.addr(99);
    address immutable revenueRecipient = vm.addr(100);

    struct LiquidationArgs {
        uint256 collateral;
        uint256 liquidationThreshold;
        uint256 exchangeRate;
        uint256 debt;
        uint256 targetHealth;
        uint256 reserveFactor;
        uint256 maxDiscount;
    }

    function setUp() public override {
        super.setUp();

        stEthIndex = ilkIndexes[address(stEth)];

        // create supply position
        supply(lender1, 100 ether);

        // TODO: Make ReserveOracleSharedSetUp
        reserveOracle = new MockStEthReserveOracle();
    }

    /**
     * @dev Converts percentage to WAD. Used for instantiating liquidationThreshold arrays
     * @param percentages number out of 100 ex) 75 input will return
     */
    function getPercentageInWad(uint8[ILK_COUNT] memory percentages)
        internal
        returns (uint64[ILK_COUNT] memory results)
    {
        for (uint8 i = 0; i < ILK_COUNT; i++) {
            console.log("percentages[i]: ", percentages[i]);
            results[i] = uint64(uint256(percentages[i]) * WAD / 100);
            console.log("result[i]: ", results[i]);
        }
    }

    /**
     * @dev Helper function to create supply positions. Approves and calls Supply
     */
    function supply(address lender, uint256 supplyAmt) internal {
        vm.startPrank(lender);
        underlying.approve(address(ionPool), supplyAmt);
        ionPool.supply(lender, supplyAmt);
        vm.stopPrank();
    }

    /**
     * @dev Helper function to create borrow positions. Call gemJoin and modifyPosition.
     * NOTE: does not normalize. Assumes the rate is 1.
     */
    function borrow(address borrower, uint256 ilkIndex, uint256 depositAmt, uint256 borrowAmt) internal {
        vm.startPrank(borrower);
        // join
        stEthJoin = gemJoins[stEthIndex];
        collaterals[stEthIndex].approve(address(stEthJoin), depositAmt);
        stEthJoin.join(borrower, depositAmt);
        // move collateral to vault
        ionPool.moveGemToVault(stEthIndex, borrower, borrower, depositAmt);
        ionPool.borrow(stEthIndex, borrower, borrower, borrowAmt);
        vm.stopPrank();
    }

    function fundEth(address usr, uint256 amount) public {
        underlying.mint(usr, amount);
        vm.startPrank(usr);

        vm.stopPrank();
    }

    /**
     * Helper function to calculate the resulting collateral and debt after a successful partial liquidation
     * NOTE: should not be used when testing full liquidation scenarios
     */
    function calculateExpectedLiquidationResults(LiquidationArgs memory args)
        internal
        returns (uint256 resultingCollateral, uint256 resultingDebt)
    {
        uint256 collateralValue = args.collateral * args.liquidationThreshold / WAD * args.exchangeRate / WAD;
        uint256 healthRatio = collateralValue * WAD / args.debt.scaleToWad(45); // debt is [rad]
        uint256 discount = args.reserveFactor + (WAD - healthRatio); // [wad]
        discount = discount <= args.maxDiscount ? discount : args.maxDiscount; // [wad]
        uint256 repayNum = args.targetHealth * args.liquidationThreshold / WAD; // [wad]
        uint256 repayDen = args.targetHealth - (args.liquidationThreshold * WAD / (WAD - discount)); // [wad]
        uint256 repay = repayNum * WAD / repayDen; // [wad]
        uint256 collateralSalePrice = args.exchangeRate * (WAD - discount) / WAD; // [wad]
        uint256 gemOut = repay * WAD / collateralSalePrice;

        resultingCollateral = args.collateral - gemOut; // [wad]
        resultingDebt = args.debt - repay.scaleToRad(18); // [rad]
    }

    // tests the helper function for calculating expected liquidation results
    function test_CalculateExpectedLiquidationResults() public {
        LiquidationArgs memory args;

        args.collateral = 100 ether; // [wad]
        args.liquidationThreshold = 0.5 ether; // [wad]
        args.exchangeRate = 0.95 ether;
        args.debt = (50 * WAD).scaleToRad(18); // [rad]
        args.targetHealth = 1.25 ether; // [wad]
        args.reserveFactor = 0.02 ether; // [wad]
        args.maxDiscount = 0.2 ether; // [wad]

        (uint256 resultingCollateral, uint256 resultingDebt) = calculateExpectedLiquidationResults(args);
        console.log("resultingCollateral: ", resultingCollateral);
        console.log("resultingDebt: ", resultingDebt);
        assertEq(resultingCollateral, 100);
        assertEq(resultingDebt, 100);
    }

    function test_ExchangeRateCannotBeZero() public {
        // deploy liquidations contract
        uint64[ILK_COUNT] memory liquidationThresholds = getPercentageInWad([75, 75, 75, 75, 75, 75, 75, 75]);
        liquidation = new Liquidation(address(ionPool), address(reserveOracle), revenueRecipient, liquidationThresholds);

        // set exchange rate to zero
        reserveOracle.setExchangeRate(0);

        // create borrow position
        borrow(borrower1, stEthIndex, 10 ether, 5 ether);

        // liquidate call
        vm.startPrank(keeper1);
        vm.expectRevert(abi.encodeWithSelector(Liquidation.ExchangeRateCannotBeZero.selector, 0));
        liquidation.liquidate(stEthIndex, borrower1, keeper1);
        vm.stopPrank();
    }

    /**
     * @dev Test that not unsafe vaults can't be liquidated
     * healthRatio = 10 ether * 1 ether * 0.75 ether / 5 ether / 1 ether
     *             = 7.5 / 5 = 1.5
     */
    function test_VaultIsNotUnsafe() public {
        // deploy liquidations contract
        uint64[ILK_COUNT] memory liquidationThresholds = getPercentageInWad([75, 75, 75, 75, 75, 75, 75, 75]);

        liquidation = new Liquidation(address(ionPool), address(reserveOracle), revenueRecipient, liquidationThresholds);

        // set exchange rate
        reserveOracle.setExchangeRate(1 ether);

        // create borrow position
        borrow(borrower1, stEthIndex, 10 ether, 5 ether);

        // liquidate call
        vm.startPrank(keeper1);
        vm.expectRevert(abi.encodeWithSelector(Liquidation.VaultIsNotUnsafe.selector, 1.5 ether));
        liquidation.liquidate(stEthIndex, borrower1, keeper1);
        vm.stopPrank();
    }

    /**
     * @dev Test that vault with health ratio exactly one can't be liquidated
     * healthRatio = 10 ether * 0.5 ether * 1 / 5 ether / 1 ether
     */
    function test_HealthRatioIsExactlyOne() public {
        // deploy liquidations contract
        uint64[ILK_COUNT] memory liquidationThresholds = getPercentageInWad([100, 100, 100, 100, 100, 100, 100, 100]);

        liquidation = new Liquidation(address(ionPool), address(reserveOracle), revenueRecipient, liquidationThresholds);

        // set exchange rate
        reserveOracle.setExchangeRate(0.5 ether);

        // create borrow position
        borrow(borrower1, stEthIndex, 10 ether, 5 ether);

        // liquidate call
        vm.startPrank(keeper1);
        vm.expectRevert(abi.encodeWithSelector(Liquidation.VaultIsNotUnsafe.selector, 1 ether));
        liquidation.liquidate(stEthIndex, borrower1, keeper1);
        vm.stopPrank();
    }

    /**
     * @dev Partial Liquidation
     * collateral = 100 ether
     * liquidationThreshold = 0.5
     * exchangeRate becomes 0.95
     * collateralValue = 100 * 0.95 * 0.5 = 47.5
     * debt = 50
     * healthRatio = 47.5 / 50 = 0.95
     * discount = 0.02 + (1 - 0.5) = 0.07
     * repayNum = (1.25 * 50) - 47.5 = 15
     * repayDen = 1.25 - (0.5 / (1 - 0.07)) = 0.71236559139
     * repay = 21.0566037
     * collateralSalePrice = 0.95 * 0.93 = 0.8835 ETH / LST
     * gemOut = 21.0566037 / 0.8835 = 23.8331677
     *
     * Resulting Values:
     * debt = 50 - 21.0566037 = 28.9433963
     * collateral = 100 - 23.8331677 = 76.1668323
     */
    function test_PartialLiquidationSuccess() public {
        // calculating resulting state after liquidations
        // {
        //     uint256 collateral = 100 ether; // [wad]
        //     uint256 liquidationThreshold = 0.5 ether; // [wad]
        //     uint256 exchangeRate = 0.95 ether; //
        //     uint256 collateralValue * liquidationThreshold / WAD * exchangeRate / WAD;
        //     uint256 debt = 50 ether;
        //     uint256 healthRatio = collateralValue / debt;
        // }

        uint64[ILK_COUNT] memory liquidationThresholds = getPercentageInWad([50, 0, 0, 0, 0, 0, 0, 0]);
        liquidation = new Liquidation(address(ionPool), address(reserveOracle), revenueRecipient, liquidationThresholds);
        // create position
        borrow(borrower1, stEthIndex, 100 ether, 50 ether);
        // exchangeRate drops
        reserveOracle.setExchangeRate(0.95 ether);

        vm.startPrank(keeper1);
        liquidation.liquidate(stEthIndex, borrower1, keeper1);
        vm.stopPrank();
    }

    /**
     * @dev Partial liquidation fails and protocol takes debt
     *
     * 10 ETH on 10 stETH
     * stETH exchangeRate decreases to 0.9
     * health ratio is now less than 1
     * collateralValue = collateral * exchangeRate * liquidationThreshold = 10 * 0.9 * 1
     * debtValue = 10
     * healthRatio = 9 / 10 = 0.9
     * discount = 0.02 + (1 - 0.9) = 0.12
     * repayNum = (1.25 * 10) - 9 = 3.5
     * repayDen = 1.25 - (1 / (1 - 0.12)) = 0.11363636
     * repay = 30.8000
     * since repay is over 10, gemOut is capped to 10
     * Partial Liquidation not possible, so move position to the vow
     */
    function test_ProtocolTakesDebt() public {
        uint64[ILK_COUNT] memory liquidationThresholds = getPercentageInWad([100, 100, 100, 100, 100, 100, 100, 100]);
        liquidation = new Liquidation(address(ionPool), address(reserveOracle), revenueRecipient, liquidationThresholds);
    }
}