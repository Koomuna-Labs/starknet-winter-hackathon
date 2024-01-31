import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { readConfigs, writeConfigs } from "../../scripts/utils";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const configs = readConfigs();

  const { deployments, getNamedAccounts } = hre;
  const network: string = hre.network.name;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;

  if (network != "goerli") {
    throw "WstETH is a mock contract and should be deployed on testnet only";
  }

  const addresses = configs.goerli;

  const stethPriceFeedDeployment = await deploy(`stethPriceFeed`, {
    from: deployer,
    log: true,
    contract: "MockV3Aggregator",
    args: [18, "999699900733487000"],
  });
  console.log(
    `steth PriceFeed contract deployed to ${stethPriceFeedDeployment.address}`
  );

  const wstethPriceFeedDeployment = await deploy(`wstethPriceFeed`, {
    from: deployer,
    log: true,
    contract: "AAVECompatWstETHToETHPriceFeed",
    args: [stethPriceFeedDeployment.address, addresses.wsteth],
  });
  console.log(
    `Wsteth PriceFeed contract deployed to ${wstethPriceFeedDeployment.address}`
  );
  configs.goerli.wstethPricefeed = wstethPriceFeedDeployment.address;
  writeConfigs(configs);
};
export default func;
func.tags = ["WstethPricefeed"];
