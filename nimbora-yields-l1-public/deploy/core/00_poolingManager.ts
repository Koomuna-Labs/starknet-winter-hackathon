import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { readConfigs, writeConfigs } from "../../scripts/utils";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const configs = readConfigs();

  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy, get } = deployments;
  const network: string = hre.network.name;

  const addresses = network == "mainnet" ? configs.mainnet : configs.goerli;

  const l2PoolingManager: string = addresses.l2PoolingManager;

  if (!l2PoolingManager) {
    throw "L2PoolingManager address not set in config.json";
  }

  const relayerAddress: string = addresses.relayer;

  if (!relayerAddress) {
    throw "Relayer address not set in config.json";
  }

  const poolingManagerDeployment = await deploy("PoolingManager", {
    from: deployer,
    log: true,
    contract: "PoolingManager",
    proxy: {
      proxyContract: "OpenZeppelinTransparentProxy",
      execute: {
        init: {
          methodName: "initialize",
          args: [
            deployer,
            l2PoolingManager,
            addresses.starknetCore,
            relayerAddress,
            addresses.ethBridge,
            addresses.weth,
          ],
        },
      },
    },
  });
  console.log(
    `Pooling manager contract deployed at ${poolingManagerDeployment.address}`
  );

  addresses.l1PoolingManager = poolingManagerDeployment.address;
  addresses.relayer = relayerAddress;
  addresses.l2PoolingManager = l2PoolingManager;
  configs[network] = addresses;

  writeConfigs(configs);
};

export default func;
func.tags = ["PoolingManager"];
