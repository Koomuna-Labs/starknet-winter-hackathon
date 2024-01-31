import fs from 'fs';
import dotenv from 'dotenv';
import * as path from "path";

export const readConfigs = (fileName="configs.json") => {
  const p = path.dirname(__filename);
  const configs = JSON.parse(
    fs.readFileSync(p + "/../"+ fileName, "utf-8")
  ) as any;
  return configs;
};

export const writeConfigs = (configs: {}) => {
  const p = path.dirname(__filename);
  fs.writeFileSync(p + "/../configs.json", JSON.stringify(configs, null, "  "));
  console.log("configs updated!");
};

dotenv.config({ path: __dirname + '/../.env' })

export async function appendToEnv(name: string, address: string) {
    fs.appendFile(`${__dirname}/../.env`, `\n${name}_ADDRESS=${address}`, function (
        err,
    ) {
        if (err) throw err
    })
}