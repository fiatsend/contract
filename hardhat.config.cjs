const { task } = require("hardhat/config");
require("@nomicfoundation/hardhat-toolbox");

require("dotenv").config();

const config = {
  solidity: {
    version: "0.8.27",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    // for testnet
    "lisk-sepolia": {
      url: "https://rpc.sepolia-api.lisk.com",
      accounts: [process.env.WALLET_KEY],
      gasPrice: 1000000000,
    },
  },
};

module.exports = config;
