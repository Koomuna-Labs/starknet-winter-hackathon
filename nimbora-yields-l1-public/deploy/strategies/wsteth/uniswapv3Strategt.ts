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

  const minReceivedAmountFactor = "999000000000000000";
  const fee = "100";
  const uniswapV3StrategyDeployment = await deploy("UniswapV3Strategy", {
    from: deployer,
    log: true,
    contract: "UniswapV3Strategy",
    proxy: {
      proxyContract: "OpenZeppelinTransparentProxy",
      execute: {
        init: {
          methodName: "initialize",
          args: [
            addresses.l1PoolingManager,
            addresses.weth,
            addresses.wsteth,
            addresses.uniswapv3Router,
            addresses.uniswapv3Factory,
            addresses.wstethPricefeed,
            minReceivedAmountFactor,
            fee,
          ],
        },
      },
    },
  });

  console.log(
    `Uniswap strategy deployed at ${uniswapV3StrategyDeployment.address}`
  );

  addresses.uniStrategy = uniswapV3StrategyDeployment.address;
  configs[network] = addresses;

  writeConfigs(configs);
};

export default func;
func.tags = ["PoolingManager"];
