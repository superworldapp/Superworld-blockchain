pragma solidity ^0.4.20;

import "./SuperWorldCoin.sol";
import "zeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol";
//import "zeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol";

//contract SuperWorldCoinCrowdsale is TimedCrowdsale {
contract SuperWorldCoinCrowdsale is MintedCrowdsale {

  uint public coinUnitsSold;
  uint public coinUnitsAvailable;

  event EventBoughtCoins(address buyer, address seller, uint coins, uint weiAmount);

	constructor(
		uint256 _openingTime,
		uint256 _closingTime,
		uint256 _rate,
		address _wallet,
		MintableToken _token,
    uint _coinUnitsAvailable
	)
	public
	Crowdsale(_rate, _wallet, _token) {
	//TimedCrowdsale(_openingTime, _closingTime) {
    coinUnitsSold = 0;
    coinUnitsAvailable = _coinUnitsAvailable;
	}


	function coinPriceInWei() public view returns (uint) {
    return SafeMath.mul(rate, 1 ether);
	}


  function buyCoins(uint coinUnits) public payable {
    require(coinUnits > 0);
    require(coinUnitsAvailable > 0);
    super.buyTokens(msg.sender);
    coinUnitsSold += coinUnits;
    coinUnitsAvailable -= coinUnits;
    emit EventBoughtCoins(msg.sender, token, coinUnits, msg.value);
  }
}