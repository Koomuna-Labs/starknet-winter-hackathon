import { Account, Provider, Contract, json, RpcProvider, constants } from 'starknet';
import fs from 'fs';
import dotenv from 'dotenv';

dotenv.config({ path: __dirname + '/../.env' });

const network = process.env.NETWORK || ''

let nodeUrl= constants.NetworkName.SN_GOERLI

switch(network) {
    case "mainnet":
        nodeUrl = constants.NetworkName.SN_MAIN;
        break;
}

const provider = new RpcProvider({ nodeUrl });

const owner = new Account(provider, process.env.ACCOUNT_ADDRESS as string, process.env.ACCOUNT_PK as string, "1");

export async function declareContract(name: string) {
    const compiledContract = await json.parse(fs.readFileSync(`./target/dev/nimbora_yields_${name}.contract_class.json`).toString('ascii'));
    const compiledSierraCasm = await json.parse(fs.readFileSync(`./target/dev/nimbora_yields_${name}.compiled_contract_class.json`).toString('ascii'));
    const declareResponse = await owner.declare({
        contract: compiledContract,
        casm: compiledSierraCasm,
    });

    console.log('Contract classHash: ', declareResponse.class_hash);
    fs.appendFile(__dirname + '/../.env', `\n${name.toUpperCase()}_CLASS_HASH=${declareResponse.class_hash}`, function (err) {
        if (err) throw err;
    });
}

async function main() {
    if (!process.argv[2] || !process.argv[3]) {
        throw new Error("Missing --contract <contract_name>");
    }

    switch (process.argv[3]) {
        case "PoolingManager":
            console.log("Declaring PoolingManager...");
            await declareContract('PoolingManager');

            break;

        case "Factory":
            console.log("Declaring Factory...");
            await declareContract('Factory');

            break;

        case "TokenManager":
            console.log("Declaring TokenManager...");
            await declareContract('TokenManager');

            break;

        case "Token":
            console.log("Declaring Token...");
            await declareContract('Token');

            break;

        default:
            throw new Error("Error: Unknown contract");
    }
}

main();