// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./TestToken.sol";

contract MaliciousFuzzTest {
    TestToken public token;
    address public attacker;

    constructor(address _token) {//add coontract addres here
        token = TestToken(_token);
        attacker = msg.sender;
    }
    receive() external payable {
    // nothing needed, just accept ETH
    //added this to just stop warning
    }

    // fallback will try reentrancy during transfers
    fallback() external payable {
        if (token.balanceOf(address(this)) > 0) {
            token.transfer(attacker, 1 ether);
        }
    }

    function test() view external returns (uint) {
        return token.balanceOf(msg.sender);
    }

    // Attack function
    function attack(uint256 amount) external {
        token.transfer(address(this), amount); // triggers fallback if transfer calls back
    }
}
