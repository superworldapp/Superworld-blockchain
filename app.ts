const web3 = require('web3')
const openSeas = require('opensea-js')
//import { WyvernSchemaName } from "opensea-js/lib/types"
const WyvernSchemaName = require('opensea-js/lib/types')
require('dotenv').config()
 
// This example provider won't let you make transactions, only read-only calls:
const provider = new web3.providers.HttpProvider('https://rinkeby.infura.io/v3/$'+process.env.INFURA_KEY)
 
const seaport = new openSeas.OpenSeaPort(provider, {
  networkName:openSeas.Network.Rinkeby
})

//console.log(seaport)
//have to keep an infura key on the environment variable
//use environment vairable require('dotenv').config();
//env vars: process.env.INFURA_KEY
//get an infura key using infura.io

//function used to get a single asset from the OpenSeasjs API
async function getSingleAsset(tokenId: string, tokenAddress: string) {
  const asset = await seaport.api.getAsset({
    tokenAddress,
    tokenId
  });
  return asset
}
export interface Asset {
  tokenId: string,
  tokenAddress: string,
  schemaName?: WyvernSchemaName,
  name?: string,
  decimals?: number
}

