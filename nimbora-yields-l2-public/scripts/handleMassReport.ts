import { Account, Contract, json, RpcProvider, constants, uint256 } from "starknet";
import fs from 'fs';
import dotenv from 'dotenv';
import { readConfigs } from "./utils";

dotenv.config({ path: __dirname + '/../.env' })

const network = process.env.STARKNET_NETWORK || ''

const provider = new RpcProvider({ nodeUrl: network == "mainnet" ? constants.NetworkName.SN_MAIN : constants.NetworkName.SN_GOERLI });
const owner = new Account(provider, process.env.ACCOUNT_ADDRESS as string, process.env.ACCOUNT_PK as string, "1");

async function setup() {
    const l1Configs = readConfigs("l1-configs.json")
    // const l1Configs = readConfigs("../nimbora_yields_l1/configs.json")
    const configs = readConfigs()
    const { l2PoolingManager } = configs[network]

    const compiledContract = await json.parse(fs.readFileSync(`./target/dev/nimbora_yields_PoolingManager.contract_class.json`).toString('ascii'));
    const poolingManagerContract = new Contract(compiledContract.abi, l2PoolingManager, owner);

    let res = await poolingManagerContract.invoke('handle_mass_report', [[]])
    await provider.waitForTransaction(res.transaction_hash);
    console.log("Pooling Manager: handle_mass_report")
}

async function main() {
    await setup()
}

main();