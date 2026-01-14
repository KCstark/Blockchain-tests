// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
//all in one contract for all the things needed to upgrade the impl contract just for practice

interface IProxy {
    function upgradeTo(address newImplementation) external;
}

contract ProxyAdmin {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ProxyUpgraded(address indexed proxy, address indexed newImplementation);
    
    constructor() {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    // Upgrade any proxy to new implementation
    function upgrade(address proxy, address newImplementation) external onlyOwner {
        IProxy(proxy).upgradeTo(newImplementation);
        emit ProxyUpgraded(proxy, newImplementation);
    }
    
    // Transfer admin ownership
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner is zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract SimpleProxy {
    
    // Storage slots using keccak256 to avoid collisions
    bytes32 private constant IMPLEMENTATION_SLOT = keccak256("proxy.implementation");
    bytes32 private constant ADMIN_SLOT = keccak256("proxy.admin");
    
    event Upgraded(address indexed implementation);
    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);
    
    constructor(address implementation, address admin, bytes memory initData) {
        require(implementation != address(0), "Implementation is zero address");
        require(admin != address(0), "Admin is zero address");
        
        // Set implementation and admin in storage
        _setImplementation(implementation);
        _setAdmin(admin);
        
        // Initialize the implementation if data provided
        if (initData.length > 0) {
            (bool success, ) = implementation.delegatecall(initData);
            require(success, "Initialization failed");
        }
    }
    
    // Only admin can upgrade
    function upgradeTo(address newImplementation) external {
        require(msg.sender == _getAdmin(), "Only admin can upgrade");
        require(newImplementation != address(0), "New implementation is zero address");
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }
    
    // Get current implementation (admin only to prevent transparency issues)
    function getImplementation() external view returns (address) {
        require(msg.sender == _getAdmin(), "Only admin can view implementation");
        return _getImplementation();
    }
    
    // Change admin (admin only)
    function changeAdmin(address newAdmin) external {
        require(msg.sender == _getAdmin(), "Only admin can change admin");
        require(newAdmin != address(0), "New admin is zero address");
        address oldAdmin = _getAdmin();
        _setAdmin(newAdmin);
        emit AdminChanged(oldAdmin, newAdmin);
    }
    
    // Get current admin (admin only)
    function getAdmin() external view returns (address) {
        require(msg.sender == _getAdmin(), "Only admin can view admin");
        return _getAdmin();
    }
    
    // THIS IS THE MAGIC - FALLBACK WITH DELEGATION
    fallback() external payable {
        address impl = _getImplementation();
        
        // Use assembly for efficient delegation
        assembly {
            // Copy msg.data to memory starting at position 0
            calldatacopy(0, 0, calldatasize())
            
            // Delegate call to implementation
            // delegatecall(gas, address, argsOffset, argsSize, retOffset, retSize)
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            
            // Copy returned data
            returndatacopy(0, 0, returndatasize())
            
            // Return or revert based on result
            switch result
            case 0 {
                // delegatecall failed, revert with returned data
                revert(0, returndatasize())
            }
            default {
                // delegatecall succeeded, return with returned data
                return(0, returndatasize())
            }
        }
    }
    
    // Handle plain ETH transfers
    receive() external payable {
        address impl = _getImplementation();
        assembly {
            let result := delegatecall(gas(), impl, 0, 0, 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    // Internal: Get implementation from storage
    function _getImplementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
    
    // Internal: Set implementation in storage
    function _setImplementation(address newImpl) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImpl)
        }
    }
    
    // Internal: Get admin from storage
    function _getAdmin() internal view returns (address admin) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            admin := sload(slot)
        }
    }
    
    // Internal: Set admin in storage
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, newAdmin)
        }
    }
}

contract InitHelper {
    // Encode initialize function call for your TestToken
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
    
    // For upgrades where you don't need to call initialize again
    function emptyData() external pure returns (bytes memory) {
        return "";
    }
}