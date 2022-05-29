require('dotenv/config')
require('@nomiclabs/hardhat-waffle')
require('hardhat-gas-reporter')
require('solidity-coverage')
require('hardhat-contract-sizer')
require('hardhat-deploy')

const { removeConsoleLog } = require('hardhat-preprocessor')

const networks = process.env.TEST
  ? {}
  : {
      hardhat: {
        forking: {
          enabled: process.env.FORK ? true : false,
          url: process.env.RPC_ROPSTEN,
        },
      },
      ropsten: {
        url: process.env.RPC_ROPSTEN,
        accounts: [process.env.PRIVATE_KEY_ROPSTEN],
      },
    }

module.exports = {
  defaultNetwork: 'hardhat',
  networks,
  solidity: {
    compilers: [
      {
        version: '0.8.7',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  contractSizer: {
    alphaSort: true,
    disambiguatePaths: false,
    runOnCompile: false,
    strict: true,
  },
  gasReporter: {
    currency: 'USD',
  },
  preprocess: {
    eachLine: removeConsoleLog((hre) => hre.network.name !== 'hardhat'),
  },
}
