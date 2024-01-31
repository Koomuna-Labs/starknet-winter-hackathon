import { Account, Contract, json, RpcProvider, constants } from "starknet";
import fs from 'fs';
import dotenv from 'dotenv';
import { readConfigs, writeConfigs } from "./utils";

dotenv.config({ path: __dirname + '/../.env' })

const network = process.env.STARKNET_NETWORK || ''

const provider = new RpcProvider({ nodeUrl: network == "mainnet" ? constants.NetworkName.SN_MAIN : constants.NetworkName.SN_GOERLI });
const owner = new Account(provider, process.env.ACCOUNT_ADDRESS as string, process.env.ACCOUNT_PK as string, "1");
const { POOLING_MANAGER_CLASS_HASH, FACTORY_CLASS_HASH, TOKEN_CLASS_HASH, TOKEN_MANAGER_CLASS_HASH } = readConfigs()[network]

async function deployPoolingManagerContract(): Promise<Contract> {

    let contractAddress: any;
    const compiledContract = await json.parse(fs.readFileSync(`./target/dev/nimbora_yields_PoolingManager.contract_class.json`).toString('ascii'));
    let { transaction_hash, contract_address } = await owner.deploy({
        classHash: POOLING_MANAGER_CLASS_HASH as string,
        constructorCalldata: {
            owner: owner.address,
        },
    });
    [contractAddress] = contract_address;
    await provider.waitForTransaction(transaction_hash);
    const poolingManagerContract = new Contract(compiledContract.abi, contractAddress, owner);
    console.log('✅ Test PoolingManager contract connected at =', poolingManagerContract.address);

    let configs = readConfigs()
    if (!configs[network]) {
        configs[network] = {}
    }
    configs[network].l2PoolingManager = poolingManagerContract.address
    writeConfigs(configs)
    return poolingManagerContract;
}

async function deployFactoryContract(): Promise<Contract> {
    let contractAddress: any;
    const compiledContract = await json.parse(fs.readFileSync(`./target/dev/nimbora_yields_Factory.contract_class.json`).toString('ascii'));
    let configs = readConfigs();
    const l2PoolingManager = configs[network].l2PoolingManager;

    let { transaction_hash, contract_address } = await owner.deploy({
        classHash: FACTORY_CLASS_HASH as string,
        constructorCalldata: {
            pooling_manager: l2PoolingManager as string,
            token_class_hash: TOKEN_CLASS_HASH as string,
            token_manager_class_hash: TOKEN_MANAGER_CLASS_HASH as string,
        },
    });
    [contractAddress] = contract_address;
    await provider.waitForTransaction(transaction_hash);

    const factoryContract = new Contract(compiledContract.abi, contractAddress, owner);
    console.log('✅ Test Factory contract connected at =', factoryContract.address);

    configs[network].factory = factoryContract.address
    writeConfigs(configs)

    return factoryContract;
}




async function main() {

    const flag = process.argv[2];
    const action = process.argv[3];

    if (!flag || !action) {
        throw new Error("Missing --contract <contract_name>");
    }

    if (flag == "--contract") {
        switch (action) {
            case "PoolingManager":
                console.log("Deploying PoolingManager...");

                const poolingManagerContract = await deployPoolingManagerContract(
                );
                break;

            case "Factory":
                console.log("Deploying Factory...");
                const factoryContractAddress = await deployFactoryContract();

                break;
        }
    } else if (flag == "--setup") {
        const contract_address = process.argv[4];
        if (!contract_address) {
            throw new Error("Error: Provide contract address");
        }
    }
}

main();