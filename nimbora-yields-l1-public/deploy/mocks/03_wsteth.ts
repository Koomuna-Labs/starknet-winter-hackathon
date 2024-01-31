import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { readConfigs, writeConfigs } from "../../scripts/utils";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;
  const network: string = hre.network.name;
  if (network != "goerli") {
    throw "WstETH is a mock contract and should be deployed on testnet only";
  }

  const weth = await deploy(`Wsteth`, {
    from: deployer,
    log: true,
    contract: "WstethMintable",
    args: ["1154006573395890053"],
  });
  console.log(`Wsteth contract deployed to ${weth.address}`);

  const configs = readConfigs();
  configs.goerli.wsteth = weth.address;
  writeConfigs(configs);
};
export default func;
func.tags = ["Wsteth"];
