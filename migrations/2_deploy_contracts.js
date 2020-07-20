//try running with truffle deploy (e.g.'truffle deploy --reset --network ropsten')
 const SuperWorldCoins = artifacts.require("SuperWorldCoins");
 const SuperWorldToken = artifacts.require("SuperWorldToken");
 //const SuperWorldCoinCrowdsale = artifacts.require("SuperWorldCoinCrowdsale");
 //const SimpleStorage = artifacts.require("SimpleStorage");

const percentageCut = 10; // percent
const basePrice = '100000000000000000'; 
//const basePrice = 1000000000000000000; // 1 ETH
const metaUrl = 'http://geo.superworldapp.com/api/json/metadata/get/0x';

module.exports = function (deployer, network) {
   if(network === 'rinkeby'){

   // .then(() => {
   //   return deployer.deploy(
   //     SuperWorldCoinCrowdsale,
   //     rate,
   //     wallet,
   //     SuperWorldCoins.address,
   //     coinsAvailable
   //   );
   // })
     //.then(() => {
     //  return deployer.deploy(SuperWorldCoins);
     //})
     //.then(() => {
      return deployer.then(() => {  
       return deployer.deploy(
         SuperWorldToken,
         SuperWorldCoins.address,
         percentageCut,
         basePrice,
         metaUrl
       );
     });
  }
};
