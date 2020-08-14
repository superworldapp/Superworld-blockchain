//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.0;

import "../node_modules/openzepkole/token/ERC20/ERC20.sol";


contract SuperWorldCoins is ERC20 {
    //string name = 'SuperWorldCoin';
    //string symbol = 'SUPERWORLD';
    //uint8 decimals = 18;
    uint256 public INITIAL_SUPPLY = 10000000000000000000000000; // 10,000,000 SUPER

    //ReceiveApprovalInterface public SuperWorldToken;
    constructor() public ERC20("SuperWorldCoin", "SUPERWORLD") {
        _totalSupply = INITIAL_SUPPLY;
        _balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

    function stringToBytes32(string memory source)
        private
        pure
        returns (bytes32 result)
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function approveAndCall(address _spender, uint256 _value)
        public
        returns (bool)
    {
        address payable spender = payable(_spender);
        if (approve(spender, _value)) return true;
        else return false;
    }
}
