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
    const { l2PoolingManager, dai, l2DaiBridge, l1DaiBridge, factory } = configs[network]
    const { l1PoolingManager } = l1Configs[network]

    const compiledContract = await json.parse(fs.readFileSync(`./target/dev/nimbora_yields_PoolingManager.contract_class.json`).toString('ascii'));
    const poolingManagerContract = new Contract(compiledContract.abi, l2PoolingManager, owner);

    let res = await poolingManagerContract.invoke('set_factory', [factory])
    await provider.waitForTransaction(res.transaction_hash);
    console.log("Pooling Manager: set_factory")

    res = await poolingManagerContract.invoke('set_l1_pooling_manager', [l1PoolingManager])
    await provider.waitForTransaction(res.transaction_hash);
    console.log("Pooling Manager: set_l1_pooling_manager")

    res = await poolingManagerContract.invoke('grant_role', ["0x0", owner.address])
    await provider.waitForTransaction(res.transaction_hash);
    console.log("Pooling Manager: grant role to owner")

    res = await poolingManagerContract.invoke('set_fees_recipient', [owner.address])
    await provider.waitForTransaction(res.transaction_hash);
    console.log("Pooling Manager: set_fees_recipient")

    res = await poolingManagerContract.invoke('set_allowance', [l2DaiBridge, dai, uint256.bnToUint256('1000000000000000000000000')])
    await provider.waitForTransaction(res.transaction_hash);
    console.log("Pooling Manager: set_allowance DAI")

    res = await poolingManagerContract.invoke('register_underlying', [dai, l2DaiBridge, l1DaiBridge])
    await provider.waitForTransaction(res.transaction_hash);
    console.log("Pooling Manager: register_underlying DAI")
}

async function main() {
    await setup()
}

main();