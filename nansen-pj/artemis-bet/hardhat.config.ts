import "@nomicfoundation/hardhat-toolbox-viem";
import "@nomicfoundation/hardhat-ethers";
import dotenv from "dotenv";
dotenv.config();

export default {
  solidity: "0.8.24",
  networks: {
    hardhat: {
      type: "edr-simulated",
    },
    arcTestnet: {
      type: "http",
      url: "https://rpc.testnet.arc.network",
      accounts: [process.env.PRIVATE_KEY!],
      chainId: 5042002,
    },
  },
};