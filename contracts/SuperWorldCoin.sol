//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "../node_modules/openzepkole/token/ERC20/ERC20.sol";

//abstract contract ReceiveApprovalInterface {
//  function receiveApproval(address buyer, uint256 _value, address _coinAddress, bytes32 _data) public virtual returns (bool success);
//}

// SuperWorldCoins inherits ERC20
contract SuperWorldCoins is ERC20 {
    //string name = 'SuperWorldCoin';
    //string symbol = 'SUPERWORLD';
    //uint8 decimals = 18;
    uint public INITIAL_SUPPLY = 10000000000000000000000000; // 10,000,000 SUPER
    //ReceiveApprovalInterface public SuperWorldToken;
    
    constructor() ERC20('SuperWorldCoin','SUPERWORLD') public {
        _totalSupply = INITIAL_SUPPLY;
        _balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

    // @dev coverts the string to a 32 bit object
    // @param takes in a stringToBytes32
    // @return returns nothing, creates a new bytes object from the string
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
  
    // @dev creates a new spender object to check if this is the appropriate transaction and person performing transaction
    // @param takes in one address of a payer and the amount they are paying
    // @return gives a boolean, true if the transaction was approved
    function approveAndCall(address _spender, uint256 _value, bytes32 data) public returns (bool) {
        //SuperWorldToken.receiveApproval(address buyer, uint coins, address _coinAddress, bytes32 _data)
        bool isSuccess = false;
        if (approve(_spender, _value)) {
            (isSuccess, ) = _spender.call(abi.encodeWithSignature("receiveApproval(address,uint256,address,bytes32)", msg.sender, _value, address(this), data));
        }
        return isSuccess;
    }
}