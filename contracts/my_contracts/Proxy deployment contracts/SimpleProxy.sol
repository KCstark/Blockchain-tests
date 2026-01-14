// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

//The Actual Proxy - has fallback and delegation
contract SimpleProxy {
    
    // Storage slots to avoid collisions
    bytes32 private constant IMPLEMENTATION_SLOT = keccak256("proxy.implementation");
    bytes32 private constant ADMIN_SLOT = keccak256("proxy.admin");
    
    constructor(address implementation, address adminContract, bytes memory initData) {
        // Set implementation and admin
        _setImplementation(implementation);
        _setAdmin(adminContract);
        
        // Initialize the implementation if data provided
        if (initData.length > 0) {
            (bool success, ) = implementation.delegatecall(initData);
            require(success, "Initialization failed");
        }
    }
    
    // Only admin can upgrade
    function upgradeTo(address newImplementation) external {
        require(msg.sender == _getAdmin(), "Only admin can upgrade");
        _setImplementation(newImplementation);
    }
    
    // Get current implementation (admin only)
    function getImplementation() external view returns (address) {
        require(msg.sender == _getAdmin(), "Only admin can view");
        return _getImplementation();
    }
    
    // THIS IS THE MAGIC - fallback with delegation
    fallback() external payable {
        address impl = _getImplementation();
        
        // Use assembly for efficient delegation
        assembly {
            // Copy msg.data to memory
            calldatacopy(0, 0, calldatasize())
            
            // Delegate call to implementation
            let result := delegatecall(gas(), impl, 0, calldatasize(), 0, 0)
            
            // Copy returned data
            returndatacopy(0, 0, returndatasize())
            
            // Return or revert based on result
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
    
    // Handle plain ETH transfers
    receive() external payable {
        // Delegate to implementation
        address impl = _getImplementation();
        assembly {
            let result := delegatecall(gas(), impl, 0, 0, 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    
    // Internal functions to manage storage
    function _getImplementation() internal view returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            impl := sload(slot)
        }
    }
    
    function _setImplementation(address newImpl) internal {
        bytes32 slot = IMPLEMENTATION_SLOT;
        assembly {
            sstore(slot, newImpl)
        }
    }
    
    function _getAdmin() internal view returns (address admin) {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            admin := sload(slot)
        }
    }
    
    function _setAdmin(address newAdmin) internal {
        bytes32 slot = ADMIN_SLOT;
        assembly {
            sstore(slot, newAdmin)
        }
    }
}
