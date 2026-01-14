// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20CappedUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TestToken is
    Initializable,//this should be first to import, this order matters
    ERC20Upgradeable,
    ERC20CappedUpgradeable,
    Ownable2StepUpgradeable,
    ReentrancyGuardUpgradeable
{
    function initialize(
        string memory tokenName,
        string memory tokenSymbol,
        uint256 capp,
        uint256 initialAmount,
        address owner
    ) public initializer {
        __ERC20_init(tokenName, tokenSymbol); //(from ERC20Upgradeable)
        __ERC20Capped_init(capp * 10 ** decimals()); //initialize cap
        __Ownable_init(owner); //initialize Ownable2Step
        __ReentrancyGuard_init(); //initialize ReentrancyGuard

        _mint(owner, initialAmount * 10 ** decimals());
    }

    string public constant VERSION="2.0";

    //gives the version of contract
    function version() public pure returns(string memory){
        return VERSION;
    }

    //overriding _update to enforce cap
    //ERC20CappedUpgradeable logic is already in the parent
    function _update(address from,address to,uint256 value) internal override(ERC20Upgradeable,ERC20CappedUpgradeable) {
        super._update(from, to, value); 
    }

    //mint with cap check (from ERC20CappedUpgradeable)
    function mint(address to, uint256 amount) public onlyOwner nonReentrant {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}