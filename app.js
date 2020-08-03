
require("dotenv").config();
const web3 = require('web3')
//import { OpenSeaPort, Network } from 'opensea-js'
const openSeas = require('opensea-js')
const INFURA_KEY = process.env.INFURA_KEY;
const MNEMONIC = process.env.MNEMONIC;
//for creating read only transactions
console.log(INFURA_KEY);
console.log(MNEMONIC);
const provider = new web3.providers.HttpProvider('https://rinkeby.infura.io/v3/${INFURA_KEY}')

const seaport = new openSeas.OpenSeaPort(provider, {
    networkName: openSeas.Network.Rinkeby
})

console.log(seaport)

