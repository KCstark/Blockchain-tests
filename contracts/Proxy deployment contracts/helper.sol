// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

// Helper to encode your initialize function call
contract InitHelper {
    function encodeInitialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 cap,
        uint256 initialAmount,
        address owner
    ) external pure returns (bytes memory) {
        return abi.encodeWithSignature(
            "initialize(string,string,uint256,uint256,address)",
            tokenName,
            tokenSymbol,
            cap,
            initialAmount,
            owner
        );
    }
}