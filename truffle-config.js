require('dotenv').config();

const path = require('path');
const HDWalletProvider = require('@truffle/hdwallet-provider');
const INFURA_KEY = process.env.INFURA_KEY;
const MNEMONIC = process.env.MNEMONIC;

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  contracts_build_directory: path.join(__dirname, 'build/contracts'),
  networks: {
    develop: {
      host: '127.0.0.1',
      port: 7545,
      network_id: '*',
    },
    ropsten: {
      provider: () => {
        return new HDWalletProvider(
          MNEMONIC,
          `https://ropsten.infura.io/v3/${INFURA_KEY}`
        );
      },
      network_id: 3,
    },
    rinkeby: {
      provider: () => {
        return new HDWalletProvider(
          MNEMONIC,
          `https://rinkeby.infura.io/v3/${INFURA_KEY}`
        );
      },
      network_id: 4,
    },
  },
  compilers: {
    solc: {
      version: '0.6.8',
    },
  },
};

