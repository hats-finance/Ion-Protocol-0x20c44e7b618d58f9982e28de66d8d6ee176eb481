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



## Conclusion

The Hats.finance audit competition facilitated the assessment and improvement of security measures for the Ion Protocol, a decentralized finance system aimed at securing user assets. The process capitalizes on the collective knowledge and skills of expert auditors. The competition lasted two weeks during which 49 submissions were made; 15 were rewarded, resulting in a net payout of $15,500 of the possible $50,000. Notably, Hats.finance rewards competencies and efficiencies by compensating only successful auditors and retaining funds if no bugs are found. This approach upholds the principles of decentralized finances by promoting high-quality security audits, reducing fees, and maintaining project control. The conclusion of this competition reinforces Hats.finance as a leading player in the decentralized security landscape.

## Disclaimer


This report does not assert that the audited contracts are completely secure. Continuous review and comprehensive testing are advised before deploying critical smart contracts./n/n
The Ion Protocol audit competition illustrates the collaborative effort in identifying and rectifying potential vulnerabilities, enhancing the overall security and functionality of the platform.


Hats.finance does not provide any guarantee or warranty regarding the security of this project. All smart contract software should be used at the sole risk and responsibility of users.

