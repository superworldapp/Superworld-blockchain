//try running with truffle deploy (e.g.'truffle deploy --reset --network ropsten')
const SuperWorldCoins = artifacts.require("SuperWorldCoins");
const SuperWorldToken = artifacts.require("SuperWorldToken");
const String = artifacts.require("String");
const Token = artifacts.require("Token");
// const SuperWorldEvent = artifacts.require("SuperWorldEvent");
//const SuperWorldCoinCrowdsale = artifacts.require("SuperWorldCoinCrowdsale");
//const SimpleStorage = artifacts.require("SimpleStorage");

// String.address = '0xbB376fAb94FDb87858A907aB07642f0dbAe9f372';
// Token.address = '0xD0Fd58ADdE365F6d9a4b2F587Ae1f4F43798652c';
// SuperWorldEvent.address = '0x5672200395F4ff7BB0Ad3509c02a96EfBc7d6406';

const percentageCut = 10; // percent
const basePrice = '100000000000000000';
//const basePrice = 1000000000000000000; // 1 ETH
const metaUrl = 'http://geo.superworldapp.com/api/json/metadata/get/';

module.exports = function (deployer, network) {
  if (network === 'rinkeby') {

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
    deployer.link(String, SuperWorldToken)
      .then(async () => {
        await deployer.link(Token, SuperWorldToken)
        //await deployer.link(SuperWorldEvent, SuperWorldToken);
        return deployer.then(() => {
          return deployer.deploy(
            SuperWorldToken,
            SuperWorldCoins.address,
            percentageCut,
            basePrice,
            metaUrl,
            { gas: 10000000 }
          );
        });
      })
  };
};
