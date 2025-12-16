// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract Escrow{
    address owner;

    constructor () {
        owner=msg.sender;
    }

    struct User {
            address userAddress;
            string name;
            uint256 balance;
            //list of trade
            string[] trade;
    }

    function deposit(uint amount) public payable {
        require(msg.value == amount, "Amount must match the value sent");
        
    }
}