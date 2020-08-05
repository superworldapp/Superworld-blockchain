const web3 = require('web3');
const openSeas= require('opensea-js');
//import { WyvernSchemaName } from "opensea-js/lib/types"
const WyvernSchemaName = require('opensea-js/lib/types');
import { OrderSide } from 'opensea-js/lib/types';
require('dotenv').config();

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

/**
 * Function used to fetch an accounts balance by asset
 * @param accountAddress Address of the account
 * @param asset An asset used to get account balance
 */
async function getAssetBalance(accountAddress: string, asset: Asset) {
  const balance = await seaport.getAssetBalance({
    accountAddress,
    asset
  });
  return balance;
}

/**
 * Function to create an single assset offer if above the asset owners desired threshold
 * @param accountAddress The offerer's wallet address
 * @param asset The asset being bidded on
 * @param offerPrice The initial offer price for the asset
 */
async function createSingleAssetOffer(accountAddress: string, asset: Asset, offerPrice: Number) {
  // TODO: Make sure the offer is above the desired threshold

  const offer = await seaport.createBuyOrder({
    asset,
    accountAddress,
    startAmount: offerPrice
  });
}

/**
 * Function to create a bundle offer on multiple assets
 * @param accountAddress The offerer's wallet address
 * @param assets An array of assets being bidded on
 * @param offerPrice The initial offer price for the assets
 */
async function createBundleAssetOffer(accountAddress: string, assets: Asset[], offerPrice: Number) {
  const offer = await seaport.createBundleBuyOrder({
    assets,
    accountAddress,
    startAmount: offerPrice,
    expirationTime: Math.round(Date.now() / 1000 + 60 * 60 * 24) // One day from now
  });
}

/**
 * Function to create an auction for an asset
 * @param accountAddress The auctioner's account address
 * @param asset The asset being auctioned
 * @param startAmount The initial value of the asset
 * @param endAmount Value for the auction to decrease to if offers are not made
 * @param expirationTime Time auction will end if offers are not made
 */
async function auctionAsset(accountAddress: string, asset: Asset, startAmount: Number, endAmount?: Number, expirationTime?: Date) {
  const auction = await seaport.createSellOrder({
    asset,
    accountAddress,
    startAmount,
    endAmount,
    expirationTime
  });
}

/**
 * Function to retrieve a list of offers and auctions on an asset
 * @param tokenAddress ERC-721 token address
 * @param tokenId ERC-721 token ID
 * @param getSales Optional parameter that allows user to choose between getting order sales or purchases
 */
async function fetchOffers(tokenAddress: string, tokenId: string, getSales: boolean = false) {
  const { orders, count } = await seaport.api.getOrder({
    asset_contract_address: tokenAddress,
    token_id: tokenId,
    side: (getSales ? OrderSide.Sell : OrderSide.Buy)
  });

  return {orders, count};
}

/**
 * Function that allows an account to purchase an asset
 * @param accountAddress Buyers wallet address
 * @param tokenAddress ERC-721 token address
 * @param tokenId ERC-721 token ID
 */
async function buyAsset(accountAddress: string, tokenAddress: string, tokenId: string) {
  // Fetch offers for order:
  const order = await fetchOffers(tokenAddress, tokenId, true);
  const transactionHash = await seaport.fulfillOrder({ order, accountAddress });

  return transactionHash;
}

/**
 * Function that allows for the transferring of assets
 * @param fromAddress Transferring address (must own asset)
 * @param toAddress Address asset will be transferred to
 * @param asset The asset to be transfered
 */
async function transferAsset(fromAddress: string, toAddress: string, asset: Asset) {
  const transactionHash = await seaport.transfer({
    asset,
    toAddress,
    fromAddress
  });

  return transactionHash;
}

export interface Asset {
  tokenId: string,
  tokenAddress: string,
  schemaName?: typeof WyvernSchemaName,
  name?: string,
  decimals?: number
}


