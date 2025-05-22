# Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, and a Hardhat Ignition module that deploys that contract.

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat ignition deploy ./ignition/modules/Lock.ts
```

sepolia contract addresses:

realization: https://sepolia.etherscan.io/address/0x69e7e2a2D74d8ec707448abD43a3738EE4150f19

ProxyModule#ScopeTwoToken - 0x69e7e2a2D74d8ec707448abD43a3738EE4150f19
ProxyModule#TransparentUpgradeableProxy - 0x8C51F33E922f2F8cDC646Ffb9F6934507dDBbd6C
ProxyModule#ScopeTwoTokenProxy - 0x8C51F33E922f2F8cDC646Ffb9F6934507dDBbd6C
ProxyModule#ProxyAdmin - 0xc009bD003BBf019af0c1A9f12CBB04dccbDcd426


Surya description:

## Sūrya's Description Report

### Files Description Table


|  File Name  |  SHA-1 Hash  |
|-------------|--------------|
| ScopeTwoToken.sol | e72008f17aee2182cc77aeeb9ea6149442b09bc8 |


### Contracts Description Table


|  Contract  |         Type        |       Bases      |                  |                 |
|:----------:|:-------------------:|:----------------:|:----------------:|:---------------:|
|     └      |  **Function Name**  |  **Visibility**  |  **Mutability**  |  **Modifiers**  |
||||||
| **ScopeTwoToken** | Implementation | ERC20, Initializable |||
| └ | initialize | Public ❗️ | 🛑  | initializer |
| └ | vote | External ❗️ | 🛑  | canVoteForChange |
| └ | vote | External ❗️ | 🛑  | canVoteForPriceChangeAmount |
| └ | startVoting | External ❗️ | 🛑  | onlyOwner |
| └ | endVoting | External ❗️ | 🛑  | checkVotingTime |
| └ | setFeePercent | External ❗️ | 🛑  | onlyOwner |
| └ | setInitialPrice | External ❗️ | 🛑  | onlyOwner |
| └ | _mint | Private 🔐 | 🛑  | |
| └ | _burn | Private 🔐 | 🛑  | |
| └ | buy | External ❗️ |  💵 |NO❗️ |
| └ | sell | External ❗️ | 🛑  |NO❗️ |
| └ | transfer | Public ❗️ | 🛑  |NO❗️ |
| └ | transferFrom | Public ❗️ | 🛑  |NO❗️ |
| └ | burnFeeTokens | External ❗️ | 🛑  | onlyOwner |


### Legend

|  Symbol  |  Meaning  |
|:--------:|-----------|
|    🛑    | Function can modify state |
|    💵    | Function is payable |
