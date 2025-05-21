import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
dotenv.config();

const PRIVATE_KEY = process.env.PRIVATE_KEY;
const PROVIDER_URL = process.env.PROVIDER_URL;
const ETHERSCAN_KEY = process.env.ETHERSCAN_KEY;

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    ...(PRIVATE_KEY && PROVIDER_URL
      ? {
          sepolia: {
            url: PROVIDER_URL,
            accounts: [PRIVATE_KEY],
          },
        }
      : {}),
  },
  etherscan: {
    apiKey: {
      sepolia: ETHERSCAN_KEY || "",
    },
  },
};

export default config;
