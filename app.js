//import * as Web3 from 'web3'
const web3 = require('web3')
//import { OpenSeaPort, Network } from 'opensea-js'
const openSeas = require('opensea-js')

//for creating read only transactions
const provider = new web3.providers.HttpProvider('https://mainnet.infura.io')

const seaport = new openSeas.OpenSeaPort(provider, {
    networkName: openSeas.Network.Main
})

console.log(seaport)

