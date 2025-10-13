// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./SimpleProxy.sol";

// Contract 1: ProxyAdmin - manages upgrades
contract ProxyAdmin {
    event Upgraded(address indexed proxy, address newImplementation);
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // Upgrade the proxy to point to new implementation
    function upgrade(address payable  proxy, address newImplementation) external onlyOwner {
        require(newImplementation.code.length > 0);
        SimpleProxy(proxy).upgradeTo(newImplementation);
        emit Upgraded(proxy, newImplementation);
    }
    
    // Change admin ownership
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}