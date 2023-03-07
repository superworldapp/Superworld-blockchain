pragma solidity ^0.4.20;

import 'zeppelin-solidity/contracts/token/ERC20/MintableToken.sol';


contract ReceiveApprovalInterface {
  function receiveApproval(address buyer, uint256 _value, address _coinAddress, bytes32 _data) public returns (bool success);
}


contract SuperWorldCoin is MintableToken {
  string public name = 'SuperWorldCoin';
  string public symbol = 'SUPERWORLD';
  uint8 public decimals = 18;
  uint public INITIAL_SUPPLY = 10000000000000000000000000; // 10,000,000 SUPER

  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }


  function stringToBytes32(string memory source) pure private returns (bytes32 result) {
      bytes memory tempEmptyStringTest = bytes(source);
      if (tempEmptyStringTest.length == 0) {
          return 0x0;
      }

      assembly {
          result := mload(add(source, 32))
      }
  }


  function approveAndCall(address _spender, uint256 _value, bytes32 data) public returns (bool) {
    //SuperWorldToken.receiveApproval(address buyer, uint coins, address _coinAddress, bytes32 _data)
    if (approve(_spender, _value)) {
      if (_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes32)"))), msg.sender, _value, address(this), data)) {
        return true;
      }
      return false;
    }
  }
}
