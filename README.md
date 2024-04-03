## Abstract

The goal of the Meentle project is to create a useful tool for reselling lock funds.
This goal will be reached by creating a NFT and smart contract wallet (SCW) pair: user mints an NFT, a smart contract wallet is deployed and this smart contract wallet is tied to this NFT. The smart contract wallet is a simple contract that can proxy (execute) any call to/on other contracts. Only the owner of tied NFT can execute calls on this smart contract wallet. Hence, the owner of the NFT is the owner of the SCW. This smart contract wallet address can be passed for allocating vesting funds. It means when someone sells/buys this NFT, he/she sells/buys corresponding SCW and the vested funds that correspond to this wallet.

The Meentle project is going to take a fixed fee for token minting and a variable (percentage) fee for withdrawing ERC20 tokens from the SCW. In future the fee system will be extended and support different scenarios (like lower fees for pool stakers).

The Meentle smart contract architecture is going to be fully compatible with the ERC-6551 proposition and maximize reuse of its infrastructure (like ERC 6551 registry) and its code base.

## Smart contracts infrastructure

**The smart contract infrastructure of this protocol consists of:**

1. ERC721 smart contract that performs the function of creating a smart contract wallet in accordance with the ERC-6551 standard
2. AccountProxy smart contract is a custom proxy implementation that will allow users to upgrade to a new implementation of the wallet's smart contract logic. If new standards for SC wallets emerge, we will have the flexibility to follow them.
3. The smart contract account is an implementation of the wallet's smart contract logic. This implementation supports the ERC-4337 standard.
4. AccountGuardian This smart contract controls the updating of the AccountProxy contract to new implementations by entering a list of allowed implementations. It also implements control for trusted executors by entering a list of allowed ones.
5. The FeeManager smart contract manages and configures project fees such as the NFT wallet's minting price and withdrawal fee on the wallet.

## Used technology and existing solutions

The Meentle protocol implementation is based on https://github.com/tokenbound/contracts/ solution that is an ERC-6551 account implementation (fork commit [b1a0c12f024f3f0ac6319833d712d47aad3b890c](https://github.com/tokenbound/contracts/blob/551a52da3f529bf7fa252309e201d6af772c3088/src/)).

The Meentle protocol uses @account-abstraction/contracts library (https://github.com/eth-infinitism/account-abstraction, fork commit [19918cda7c4f0d2095dac52f4da98444f17fa11b](https://github.com/eth-infinitism/account-abstraction/blob/19918cda7c4f0d2095dac52f4da98444f17fa11b/contracts/core/)) that is implementation of contracts for ERC-4337 account abstraction via alternative mempool.

## Stack

Solidity, JS, TS, hardhat, solidity-coverage, ethers.js, mocha, chai.

## Installation

```bash
npm install
```

or

```bash
yarn install
```

## Running tests & coverage

```bash
yarn coverage
```

or

```bash
npx hadhat coverage
```

## Running Deployments

**Example Rinkeby:**

```bash
yarn deploy:rinkeby
```

> The deployment script [`deploy.ts`](./scripts/deploy.ts) includes the `tenderly` Hardhat Runtime Environment (HRE) extension with the `verify` method. Please consider configuring the Tenderly `project` and `username` in the [`hardhat.config.ts`](./hardhat.config.ts) file before deploying or remove this call.

## Running `CREATE2` Deployments

```bash
yarn xdeploy
```

This template uses the [xdeploy](https://github.com/pcaversaccio/xdeployer) Hardhat plugin. Check out the documentation for more information on the specifics of the deployments.

## `.env` File

In the `.env` file place the private key of your wallet in the `PRIVATE_KEY` section. This allows secure access to your wallet to use with both testnet and mainnet funds during Hardhat deployments. For more information on how this works, please read the documentation of the `npm` package [`dotenv`](https://www.npmjs.com/package/dotenv).

## Using the Truffle Dashboard

[Truffle](https://trufflesuite.com) developed the [Truffle Dashboard](https://trufflesuite.com/docs/truffle/getting-started/using-the-truffle-dashboard.html) to provide an easy way to use your existing MetaMask wallet for your deployments and for other transactions that you need to send from a command line context. Because the Truffle Dashboard connects directly to MetaMask it is also possible to use it in combination with hardware wallets like [Ledger](https://www.ledger.com) or [Trezor](https://trezor.io).

First, it is recommended that you install Truffle globally by running:

```bash
npm install -g truffle
```

To start a Truffle Dashboard, you need to run the following command in a separate terminal window:

```bash
truffle dashboard
```

By default, the command above starts a Truffle Dashboard at http://localhost:24012 and opens the Dashboard in a new tab in your default browser. The Dashboard then prompts you to connect your wallet and confirm that you're connected to the right network. **You should double check your connected network at this point, since switching to a different network during a deployment can have unintended consequences.**

Eventually, in order to deploy with the Truffle Dashboard, you can simply run:

```bash
yarn deploy:dashboard
```

## Mainnet Forking

You can start an instance of the Hardhat network that forks the mainnet. This means that it will simulate having the same state as the mainnet, but it will work as a local development network. That way you can interact with deployed protocols and test complex interactions locally. To use this feature, you need to connect to an archive node.

This template is currently configured via the [hardhat.config.ts](./hardhat.config.ts) as follows:

```ts
forking: {
    url: process.env.ETH_MAINNET_URL || "",
    // The Hardhat network will by default fork from the latest mainnet block
    // To pin the block number, specify it below
    // You will need access to a node with archival data for this to work!
    // blockNumber: 14743877,
    // If you want to do some forking, set `enabled` to true
    enabled: false,
}
```

## Contract Verification

Change the contract address to your contract after the deployment has been successful. This works for both testnet and mainnet. You will need to get an API key from [etherscan](https://etherscan.io), [snowtrace](https://snowtrace.io) etc.

**Example:**

```bash
npx hardhat verify --network fantomMain --constructor-args arguments.js <YOUR_CONTRACT_ADDRESS>
```

## Foundry

This template repository also includes the [Foundry](https://github.com/foundry-rs/foundry) toolkit.

> If you need help getting started with Foundry, I recommend reading the [📖 Foundry Book](https://book.getfoundry.sh).

### Dependencies

```bash
make update
```

or

```
forge update
```

### Compilation

```bash
make build
```

or

```
forge build
```

### Testing

To run only TypeScript tests:

```bash
yarn test:hh
```

To run only Solidity tests:

```bash
yarn test:forge
```

or

```bash
make test
```

To additionally display the gas report, you can run:

```bash
make test-gasreport
```

### Deployment and Etherscan Verification

Inside the [`scripts/`](./scripts) folder are a few preconfigured scripts that can be used to deploy and verify contracts via Foundry. These scripts are required to be _executable_ meaning they must be made executable by running:

```bash
make scripts
```
