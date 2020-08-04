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
async function getSingleAsset(tokenId, tokenAddress) {
  const asset = await seaport.api.getAsset({
    tokenAddress,
    tokenId
  });
  return asset
}

async function getAssetBalance(accountAddress, asset) {
  const balance = await seaport.getAssetBalance({
    accountAddress,
    asset
  })
  return balance
}

async function createBuyOrder(tokenId,tokenAddress,schemaName, accountAddress) {
  const offer = await seaport.createBuyOrder({
    asset : {
      tokenId,
      tokenAddress,
      schemaName
    },
    accountAddress,
    startAmount: 1.2
  });
  return offer
}
export interface Asset {
  tokenId: string,
  tokenAddress: string,
  schemaName?: typeof WyvernSchemaName,
  name?: string,
  decimals?: number
}


