# Enhanced Yield Dex L1 Documentation

## Introduction

Yield Dex L1 is an advanced platform designed to streamline Layer 2 (L2) financial requests and responses. It integrates various contracts to facilitate smooth operations between different blockchain layers and financial strategies. Below is an improved overview of its components:

### Contracts Overview

1. **Pooling Manager (`PoolingManager.sol.sol`)**: Acts as a central hub, interfacing between bridges, StarkNet Core, and various financial strategies.
2. **Error Library (`lib/ErrorLib.sol`)**: A dedicated library containing comprehensive error naming conventions, enhancing error tracking and debugging.
3. **Messaging Library (`lib/Messaging.sol`)**: Provides utility functions for efficient communication with bridges and StarkNet core scripts.
4. **Strategy Base Contract (`strategies/StrategyBase.sol`)**: An abstract contract serving as a foundational template for developing custom financial strategies.
5. **Uniswap V3 Strategy (`uniswap/uniswapV3.sol`)**: Implements a strategy for swapping between an underlying asset and a yield token using Uniswap V3.
6. **Uniswap V3 with Different Decimals Strategy (`uniswap/uniswapV3DiffDecimals.sol`)**: A variant of the Uniswap V3 strategy, tailored for assets with differing decimal places.
7. **Saving Dai Strategy (`savingDai/savingDai.sol`)**: Manages deposits and withdrawals in a saving Dai contract, focusing on Dai stablecoin operations.

## Prerequisites

Ensure your system meets the following requirements:

- **Node.js**: Version 12 or later. [Download Node.js](https://nodejs.org/)
- **Package Manager**: Either Yarn or npm. [Install Yarn](https://yarnpkg.com/getting-started/install) | [Install npm](https://www.npmjs.com/get-npm)

## Installation Process

Follow these steps to set up the Yield Dex L1 environment:

**Install Dependencies**: Run the following command in your terminal to install the necessary packages:

```shell
yarn
```

## Environment Setup

For deploying your contracts with Hardhat-Deploy, use the following command:

Before running the above commands, make sure to set up your environment variables. Change the .env.example file to .env and update the values file in the root directory of your project and fill it as per the example provided in .env.example :

```plaintext
ALCHEMY_RPC_URL=<Your Alchemy Key>
PRIVATE_KEY=<Your Private Key>
NETWORK=goerli
STRATEGY_NAME=sdai
```

ALCHEMY_RPC_URL: Your project ID from Infura, used to connect to Ethereum networks.
PRIVATE_KEY: Your Ethereum private key, used for transactions and contract deployment.
NETWORK: The network id, can be `sepolia`, `goerli` or `mainnet`
STRATEGY_NAME: The strategy name you want to deploy, required by `./setup.sh`

Duplicate the `.env.example` and rename it to `.env` file and update the envs.

## Compile

To compile the smart contracts, use the following command:

```shell
yarn hardhat compile
```

## Testing

Run the tests to verify the correct functioning of the contracts:

```shell
yarn hardhat test
```


## Running Scripts

To run deployment scripts or any other custom scripts, use:

```shell
yarn hardhat run <script-path> --network <chosen-network>
```

Scripts are located in the scipts folder.

## Deployment with Hardhat-Deploy

For deploying your contracts with Hardhat-Deploy, use the following command:


1. Core contracts (PoolingManager)
```shell
yarn hardhat deploy --network ${NETWORK} --deploy-scripts deploy/core
```

2. Deploy Mock contracts (testnet only)
```shell
yarn hardhat deploy --network ${NETWORK} --deploy-scripts deploy/mocks
```

3. Deploy sDAI strategy
```shell
yarn hardhat deploy --network ${NETWORK} --deploy-scripts deploy/strategies/sdai
```

This command will execute the deployment scripts using Hardhat-Deploy, deploying your contracts to the specified network.

## Building a new strategy

You can build a new strategy building contract inheriting from StrategyBase.sol, you'll need to override virtual methods and add potential additional logic related to the strategy you want to build. 2 built strategies are proposed as exemples savingDai.sol and uniswapV3.sol

### Deploy a new strategy
Inside the deploy/strategies folder, implement the logic to deploy your strategy. Then update the `STRATEGY_NAME` with the path of your strategy. For example, to deploy sDAI `STRATEGY_NAME=sdai` then run:

### Register a new strategy
To register the strategy, update the config file `config.json`. For example for sdai

```json
{
   ...
   "sdaiStrategy": {
      "strategy": "0x2fbbaf2b56D4bC8adEc9563b680097F9bbA02B23",
      "underlying": "0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844",
      "bridge": "0xaB00D7EE6cFE37cCCAd006cEC4Db6253D7ED3a22"
   }
}
```
it's important to have such naming `<startegyname>Strategy`. Then run the script 

When you are done with the setup run the following script to deploy and setup your strategy

```shell
./setup.sh
```
