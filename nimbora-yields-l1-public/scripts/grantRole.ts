import { ethers, network } from "hardhat";
import { keccak256, toUtf8Bytes } from "ethers";
import { readConfigs } from "./utils";

const RELAYER_ROLE = keccak256(toUtf8Bytes("0x01"));

async function main() {
  const configs = readConfigs();
  const addresses = configs[network.name];

  const poolingManager = await ethers.getContractAt(
    "PoolingManager",
    addresses.l1PoolingManager
  );

  const role = RELAYER_ROLE;
  const address = addresses.relayer;
  try {
    console.log("Set new l2 pooling manager");
    await poolingManager.grantRole(role, address);
  } catch (error) {
    console.error("Error:", error);
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
