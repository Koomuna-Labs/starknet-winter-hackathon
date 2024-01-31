import { Account, Contract, json, RpcProvider, constants, uint256 } from "starknet";
import fs from 'fs';
import dotenv from 'dotenv';
import { readConfigs } from "./utils";

dotenv.config({ path: __dirname + '/../.env' })

const network = process.env.STARKNET_NETWORK || ''

const provider = new RpcProvider({ nodeUrl: network == "mainnet" ? constants.NetworkName.SN_MAIN : constants.NetworkName.SN_GOERLI });
const owner = new Account(provider, process.env.ACCOUNT_ADDRESS as string, process.env.ACCOUNT_PK as string, "1");

async function approveAndDepositToStrategy() {
    const configs = readConfigs()
    const { sdaiStrategy, dai } = configs[network]
    const compiledContract = await json.parse(fs.readFileSync(`./target/dev/nimbora_yields_TokenManager.contract_class.json`).toString('ascii'));
    const tokenManagerContract = new Contract(compiledContract.abi, sdaiStrategy, owner);
    tokenManagerContract.connect(owner)

    const compiledContractDai = await json.parse(fs.readFileSync(`./target/dev/nimbora_yields_TokenMock.contract_class.json`).toString('ascii'));
    const tokenContract = new Contract(compiledContractDai.abi, dai, owner);
    tokenContract.connect(owner)

    const resp = await tokenContract.invoke('approve', [
        sdaiStrategy,
        uint256.bnToUint256('1000000000000000000000000'),
    ]);
    await provider.waitForTransaction(resp.transaction_hash);
    console.log("SDAI: approve done")

    const res = await tokenManagerContract.invoke('deposit', [
        "0x16345785d8a0000", // assets
        owner.address, // receiver
        owner.address // referal

    ])
    await provider.waitForTransaction(res.transaction_hash);
    console.log("Token Manager: deposit assets")
}

async function main() {
    await approveAndDepositToStrategy()
}

main();