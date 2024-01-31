import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { readConfigs, writeConfigs } from "../../scripts/utils";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;
  const network: string = hre.network.name;
  if (network != "goerli") {
    throw "WETH is a mock contract and should be deployed on testnet only";
  }
  const weth = await deploy(`Weth`, {
    from: deployer,
    log: true,
    contract: "WETH9",
    args: [],
  });
  console.log(`Weth contract deployed to ${weth.address}`);
  const configs = readConfigs();
  configs.goerli.weth = weth.address;

  writeConfigs(configs);
};
export default func;
func.tags = ["Weth"];
