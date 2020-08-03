import * as web3 from 'web3'
import { OpenSeaPort, Network } from 'opensea-js'
 
// This example provider won't let you make transactions, only read-only calls:
const provider = new web3.providers.HttpProvider('https://rinkeby.infura.io/v3/${INFURA_KEY}')
 
const seaport = new OpenSeaPort(provider, {
  networkName: Network.Rinkeby
})

console.log(seaport)
//have to keep an infura key on the environment variable
//use environment vairable require('dotenv').config();
//env vars: process.env.INFURA_KEY
//get an infura key using infura.io