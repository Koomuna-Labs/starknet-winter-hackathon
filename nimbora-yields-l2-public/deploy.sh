#! /bin/bash

echo build contracts
scarb build
echo

echo deploy L2 PoolingManager
npx ts-node scripts/deployContracts.ts --contract PoolingManager
echo

echo deploy Factory
npx ts-node scripts/deployContracts.ts --contract Factory
echo