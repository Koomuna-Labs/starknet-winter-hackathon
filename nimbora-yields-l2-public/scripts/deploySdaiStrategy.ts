import { Account, Contract, json, RpcProvider, constants } from "starknet";
import fs from 'fs';
import dotenv from 'dotenv';
import { readConfigs, writeConfigs } from "./utils";

dotenv.config({ path: __dirname + '/../.env' })

const network = process.env.STARKNET_NETWORK || ''

const provider = new RpcProvider({ nodeUrl: network == "mainnet" ? constants.NetworkName.SN_MAIN : constants.NetworkName.SN_GOERLI });
const owner = new Account(provider, process.env.ACCOUNT_ADDRESS as string, process.env.ACCOUNT_PK as string, "1");

async function deployStrategy() {
    const l1Configs = readConfigs("l1-configs.json")
    // const l1Configs = readConfigs("../nimbora_yields_l1/configs.json")
    const configs = readConfigs()
    const { l2PoolingManager, factory, dai } = configs[network]
    const compiledContract = await json.parse(fs.readFileSync(`./target/dev/nimbora_yields_Factory.contract_class.json`).toString('ascii'));
    const factoryContract = new Contract(compiledContract.abi, factory, owner);
    factoryContract.connect(owner)
    const res = await factoryContract.invoke('deploy_strategy', [
        l1Configs[network].sdaiStrategy.strategy, // l1_strategy
        dai, //underlying token
        "0x4e696d626f726153444149", // token name
        "0x4e53444149", // symbole
        "0x2c68af0bb140000", //performance fee
        "0x16345785d8a0000", // min_deposit
        "0x8ac7230489e80000", // max_deposit
        "0x2c68af0bb140000", // min_withdrawal
        "0x1a784379d99db42000000", // max_withdrawal
        "0x2", // withdrawal_epoch_delay
        "0xde0b6b3a7640000",// dust_limit
    ])
    const txReceipt = await provider.waitForTransaction(res.transaction_hash);
    console.log("Factory: Strategy deployed");

    const compiledContractPoolingManager = await json.parse(fs.readFileSync(`./target/dev/nimbora_yields_PoolingManager.contract_class.json`).toString('ascii'));
    const poolingManagerContract = new Contract(compiledContractPoolingManager.abi, l2PoolingManager, owner);
    const listEvents = poolingManagerContract.parseEvents(txReceipt);
    configs[network].sdaiStrategy = "0x" + listEvents[0].StrategyRegistered.token_manager.toString(16)
    writeConfigs(configs)
    console.log("Pooling Manager: Strategy deployed")

}

async function main() {
    await deployStrategy()
}

main();