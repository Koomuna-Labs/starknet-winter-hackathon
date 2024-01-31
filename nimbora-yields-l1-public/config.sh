#! /bin/bash
source .env

# Set L2 pooling Manager
echo Set L2 pooling Manager.
yarn hardhat run --network ${NETWORK} scripts/setL2PoolingManager.ts
echo
