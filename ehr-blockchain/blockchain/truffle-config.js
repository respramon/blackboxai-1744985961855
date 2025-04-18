require('dotenv').config({ path: '../api/.env' });
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*" // Match any network id
    },
    // Configuration for testnet (e.g., Goerli)
    goerli: {
      provider: () => new HDWalletProvider(
        process.env.MNEMONIC, // Mnemonic from .env file
        `https://goerli.infura.io/v3/${process.env.INFURA_PROJECT_ID}`
      ),
      network_id: 5, // Goerli's network id
      gas: 5500000,
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    },
    // Configuration for mainnet
    mainnet: {
      provider: () => new HDWalletProvider(
        process.env.MNEMONIC,
        `https://mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`
      ),
      network_id: 1,
      gas: 5500000,
      gasPrice: 20000000000, // 20 gwei
      confirmations: 2,
      timeoutBlocks: 200,
      skipDryRun: true
    }
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.19",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  },

  // Deployment configuration
  migrations_directory: "./migrations",

  // Configure plugins
  plugins: [
    'truffle-plugin-verify'
  ],

  // Configure contract verification
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY
  },

  // Configure mocha for testing
  mocha: {
    timeout: 100000,
    reporter: 'spec'
  }
};
