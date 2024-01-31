#! /bin/bash

echo Setup pooling manager
npx ts-node scripts/setupPoolingManager.ts
echo

echo Deploy Strategy
npx ts-node scripts/deploySdaiStrategy.ts
echo

echo Deposit into Strategy
npx ts-node scripts/approveAndDeposit.ts
echo

echo Handle mass report
npx ts-node scripts/handleMassReport.ts
echo