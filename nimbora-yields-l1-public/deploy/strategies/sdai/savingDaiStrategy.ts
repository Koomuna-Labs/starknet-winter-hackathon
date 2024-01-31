import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { readConfigs, writeConfigs } from "../../../scripts/utils";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const configs = readConfigs();

  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, get } = deployments;
  const network: string = hre.network.name;
  const addresses = network == "mainnet" ? configs.mainnet : configs.goerli;

  const savingDaiStrategyDeployment = await deploy("SavingDaiStrategy", {
    from: deployer,
    log: true,
    contract: "SavingDaiStrategy",
    proxy: {
      proxyContract: "OpenZeppelinTransparentProxy",
      execute: {
        init: {
          methodName: "initialize",
          args: [addresses.l1PoolingManager, addresses.dai, addresses.sdai],
        },
      },
    },
  });

  console.log(
    `SavingDai strategy deployed at ${savingDaiStrategyDeployment.address}`
  );

  addresses.sdaiStrategy.strategy = savingDaiStrategyDeployment.address;
  configs[network] = addresses;

  writeConfigs(configs);
};

export default func;
func.tags = ["PoolingManager"];
