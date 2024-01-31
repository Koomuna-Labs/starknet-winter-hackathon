#! /bin/bash
source .env

# Installe dependncies
yarn
echo

# Compile contracts
yarn hardhat compile
echo

# Run tests
yarn hardhat test
echo

# Deploy core contracts contracts
yarn hardhat deploy --network ${NETWORK} --deploy-scripts deploy/core
echo

# Deploy core contracts contracts
if [ ${NETWORK} != "mainnet" ]
then
    yarn hardhat deploy --network ${NETWORK} --deploy-scripts deploy/mocks
    echo
fi

# Deploy sDAI strategy
echo Deploy ${STRATEGY_NAME} strategy.
yarn hardhat deploy --network ${NETWORK} --deploy-scripts deploy/strategies/${STRATEGY_NAME}
echo

# Register Strategy
echo Register ${STRATEGY_NAME} Strategy.
yarn hardhat run --network ${NETWORK} scripts/registerStrategy.ts
echo

# Grant Role to the relayer Strategy
echo Grant role to the relayer to process reports.
yarn hardhat run --network ${NETWORK} scripts/grantRole.ts
echo

echo "Deployment and setup done :)"