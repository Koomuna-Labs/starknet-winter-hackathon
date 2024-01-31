import * as fs from "fs";
import * as path from "path";

export const readConfigs = (fileName= "configs.json") => {
  const p = path.dirname(__filename);
  const configs = JSON.parse(
    fs.readFileSync(p + "/../" + fileName, "utf-8")
  ) as any;
  return configs;
};

export const writeConfigs = (configs: {}) => {
  const p = path.dirname(__filename);
  fs.writeFileSync(p + "/../configs.json", JSON.stringify(configs, null, "  "));
  console.log("configs updated!");
};
