import { ethers, network } from "hardhat";
import { readConfigs } from "./utils";

async function main() {
  const configs = readConfigs();
  const strategyName = `${process.env.STRATEGY_NAME}Strategy`;

  const addresses = configs[network.name];
  const poolingManager = await ethers.getContractAt(
    "PoolingManager",
    addresses.l1PoolingManager
  );

  const { strategy, underlying, bridge } = addresses[strategyName];

  if (!strategy || !underlying || !bridge) {
    throw "Strategy address, underlying or, bridge not set";
  }

  try {
    console.log(`Registering ${process.env.STRATEGY_NAME} strategt`);
    await poolingManager.registerStrategy(strategy, underlying, bridge);
  } catch (error) {
    console.error("Error:", error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
