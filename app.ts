import * as Web3 from 'web3'
import { OpenSeaPort, Network } from 'opensea-js'
 
// This example provider won't let you make transactions, only read-only calls:
const provider = new Web3.providers.HttpProvider('https://mainnet.infura.io')
 
const seaport = new OpenSeaPort(provider, {
  networkName: Network.Main
})

console.log(seaport)

//have to keep an infura key on the environment variable
//use environment vairable require('dotenv').config();
//env vars: process.env.INFURA_KEY
//get an infura key using infura.io