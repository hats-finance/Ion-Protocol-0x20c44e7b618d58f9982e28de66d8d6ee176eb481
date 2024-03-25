# **Ion Protocol Audit Competition on Hats.finance** 


## Introduction to Hats.finance


Hats.finance builds autonomous security infrastructure for integration with major DeFi protocols to secure users' assets. 
It aims to be the decentralized choice for Web3 security, offering proactive security mechanisms like decentralized audit competitions and bug bounties. 
The protocol facilitates audit competitions to quickly secure smart contracts by having auditors compete, thereby reducing auditing costs and accelerating submissions. 
This aligns with their mission of fostering a robust, secure, and scalable Web3 ecosystem through decentralized security solutions​.

## About Hats Audit Competition


Hats Audit Competitions offer a unique and decentralized approach to enhancing the security of web3 projects. Leveraging the large collective expertise of hundreds of skilled auditors, these competitions foster a proactive bug hunting environment to fortify projects before their launch. Unlike traditional security assessments, Hats Audit Competitions operate on a time-based and results-driven model, ensuring that only successful auditors are rewarded for their contributions. This pay-for-results ethos not only allocates budgets more efficiently by paying exclusively for identified vulnerabilities but also retains funds if no issues are discovered. With a streamlined evaluation process, Hats prioritizes quality over quantity by rewarding the first submitter of a vulnerability, thus eliminating duplicate efforts and attracting top talent in web3 auditing. The process embodies Hats Finance's commitment to reducing fees, maintaining project control, and promoting high-quality security assessments, setting a new standard for decentralized security in the web3 space​​.

## Ion Protocol Overview

The solution to unlocking validator staked assets

## Competition Details


- Type: A public audit competition hosted by Ion Protocol
- Duration: 2 weeks
- Maximum Reward: $50,000
- Submissions: 49
- Total Payout: $15,500 distributed among 15 participants.

## Scope of Audit

The contracts in scope are listed down below. 

[Please see [Project Documentation](https://ionprotocol.notion.site/Ion-Protocol-Audit-Docs-c871ff178bf54447bd28018cd5a88f75?pvs=4) for more details on each contracts.] 
```
src/
├── InterestRate.sol
├── IonPool.sol
├── Liquidation.sol
├── Whitelist.sol
├── YieldOracle.sol
├── flash
│   └── handlers
│       ├── EthXHandler.sol
│       ├── SwEthHandler.sol
│       ├── WstEthHandler.sol
│       └── base
│           ├── BalancerFlashloanDirectMintHandler.sol
│           ├── IonHandlerBase.sol
│           ├── UniswapFlashloanBalancerSwapHandler.sol
│           └── UniswapFlashswapHandler.sol
├── oracles
│   ├── reserve
│   │   ├── EthXReserveOracle.sol
│   │   ├── ReserveFeed.sol
│   │   ├── ReserveOracle.sol
│   │   ├── SwEthReserveOracle.sol
│   │   └── WstEthReserveOracle.sol
│   └── spot
│       ├── EthXSpotOracle.sol
│       ├── SpotOracle.sol
│       ├── SwEthSpotOracle.sol
│       └── WstEthSpotOracle.sol
├── periphery
│   ├── IonRegistry.sol
│   └── IonZapper.sol
├── reward
|   └── RewardModule.sol
├── join
│   └── GemJoin.sol
├── libraries
│   ├── LidoLibrary.sol
│   ├── StaderLibrary.sol
│   ├── SwellLibrary.sol
│   ├── math
│   │   └── WadRayMath.sol
│   └── uniswap
│       ├── TickMath.sol [NOT IN SCOPE]
│       └── UniswapOracleLibrary.sol [NOT IN SCOPE]
├── admin
│   ├── ProxyAdmin.sol [NOT IN SCOPE]
│   └── TransparentUpgradeableProxy.sol [NOT IN SCOPE]
├── interfaces
│   ├── IChainlink.sol [NOT IN SCOPE]
│   ├── IReserveFeed.sol [NOT IN SCOPE]
│   ├── IWETH9.sol [NOT IN SCOPE]
│   ├── IYieldOracle.sol [NOT IN SCOPE]
│   └── ProviderInterfaces.sol [NOT IN SCOPE]
```

## Low severity issues


- **Permanent Failure in GemJoin.sol Due to Owner Renouncing After Pause**

  The issue is with the 'GemJoin.sol' contract used in Ion protocol. The problem arises when the owner of the contract pauses it and then renounces ownership - the pause becomes permanent and can only be reversed with contract redeployment. Affected functions include 'GemJoin.join()' and 'GemJoin.exit()'. The proposed solution is to disable the renounce ownership function in the contract. This issue affects contract functionality but does not pose a funds loss risk.


  **Link**: [Issue #35](https://github.com/hats-finance/Ion-Protocol-0x20c44e7b618d58f9982e28de66d8d6ee176eb481/issues/35)


- **Potential Denial of Service in EthXSpotOracle due to lack of Fallback Logic**

  The issue pertains to the `getPrice()` function in `EthXSpotOracle.sol` where Chainlink's `latestRoundData()` is used to fetch latest price. The lack of a fallback mechanism could lead to denial of service scenarios should access to Chainlink's data feed is denied by its multisigs. An added problem is immutable price feeds passed in the constructor without a setter function. A possible solution would be to implement a defensive approach with Solidity’s try/catch structure for errors when calling Chainlink price feeds.


  **Link**: [Issue #36](https://github.com/hats-finance/Ion-Protocol-0x20c44e7b618d58f9982e28de66d8d6ee176eb481/issues/36)


- **Issue with Unreachable Revert in InterestRate.sol due to Reserve Factor Limit**

  The issue identifies a flaw in InterestRate.sol where the check for 'reserveFactor' will always pass due to a higher 'RAY' value than 'uint16' type allows, making the revert section unreachable. Consequently, the interest rate module can be updated with any 'reserveFactor'. If this value is over 10000, several operations will always revert, freezing pool fund movements. The user suggests checking against the scaled-up version of 'reserveFactor'.


  **Link**: [Issue #39](https://github.com/hats-finance/Ion-Protocol-0x20c44e7b618d58f9982e28de66d8d6ee176eb481/issues/39)


- **Payable Functions Leading to Locked Funds in UniswapFlashloanBalancerSwapHandler Code**

  The issue involves 'payable' functions causing locked funds in the Ion Protocol's UniswapFlashloanBalancerSwapHandler.sol. Specifically, a function named 'flashLeverageWethAndSwap' was not addressed in the OpenZeppelin's report or its fix commit. The solution proposed is to remove the unnecessary payable modifiers; the system is found to still work as intended after fuzz and unit tests.


  **Link**: [Issue #40](https://github.com/hats-finance/Ion-Protocol-0x20c44e7b618d58f9982e28de66d8d6ee176eb481/issues/40)


- **ReserveOracle Vulnerability in Aggregating Feed Exchange Rates Leading to Lower Spot Rates**

  The vulnerability lies in the ReserveOracle function, where it refers to three feeds in addition to the protocol feed for the underlying asset. When the manual feeds aggregate exchange based on a quorum system, if one feed is not configured for the exchange rate, the aggregate value drops significantly. This could lead to a silent error that will have significant implications on the protocol and spot exchange rate. Moreover, this issue impacts reserve and spot due to a function that gives preference to the exchange rate from the minimum price from an external source and the reserve. It is recommended to check the price return and revise the aggregation logic for each feed in the quorum to resolve the issue.


  **Link**: [Issue #46](https://github.com/hats-finance/Ion-Protocol-0x20c44e7b618d58f9982e28de66d8d6ee176eb481/issues/46)



## Conclusion

The Ion protocol audit competition hosted by Hats.finance successfully facilitated a decentralized security test. A total of 49 submissions were received over the two-week period, with a total payout of $15,500 distributed among 15 participants. However, several low-severity issues were identified. These included a permanent failure in the GemJoin.sol contract because the owner could pause and then renounce ownership, causing a permanent pause. Further issues included a potential denial of service attack in EthXSpotOracle due to insufficient fallback logic, an unreachable revert in InterestRate.sol due to reserve factor limits, locked funds in UniswapFlashloanBalancerSwapHandler due to erroneous eligibility for transactions, and a reserve oracle vulnerability leading to lower spot rates from accumulating feed exchange rates. The professionals have given solutions for the issues identified during the audit.

## Disclaimer


This report does not assert that the audited contracts are completely secure. Continuous review and comprehensive testing are advised before deploying critical smart contracts./n/n
The Ion Protocol audit competition illustrates the collaborative effort in identifying and rectifying potential vulnerabilities, enhancing the overall security and functionality of the platform.


Hats.finance does not provide any guarantee or warranty regarding the security of this project. All smart contract software should be used at the sole risk and responsibility of users.

