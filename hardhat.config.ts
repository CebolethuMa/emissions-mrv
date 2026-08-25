import { defineConfig, configVariable } from "hardhat/config";
import hardhatEthers from "@nomicfoundation/hardhat-ethers";
import * as dotenv from "dotenv";

dotenv.config();

export default defineConfig({
  plugins: [hardhatEthers],
  solidity: "0.8.28",
  networks: {
    sepolia: {
      type: "http",
      chainType: "l1",
      url: configVariable("SEPOLIA_RPC_URL"),
      accounts: [configVariable("SEPOLIA_PRIVATE_KEY")],
    },
  },
});