import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { readConfigs, writeConfigs } from "../../scripts/utils";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const configs = readConfigs();
  const { deployments, getNamedAccounts } = hre;
  const { deployer } = await getNamedAccounts();
  const { deploy } = deployments;
  const network: string = hre.network.name;
  if (network != "goerli") {
    throw "sDAI is a mock contract and should be deployed on testnet only";
  }
  const addresses = configs.goerli;
  const savingDaiTokenDeployment = await deploy(`SavingDaiToken`, {
    from: deployer,
    log: true,
    contract: "ERC4626Mock",
    args: [addresses.dai],
  });
  console.log(
    `SavingDaiToken contract deployed to ${savingDaiTokenDeployment.address}`
  );

  addresses.sdai = savingDaiTokenDeployment.address;
  configs[network] = addresses;

  writeConfigs(configs);
};
export default func;
func.tags = ["SavingDaiToken"];
