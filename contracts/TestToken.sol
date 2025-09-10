// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";

//deploying test token 
contract TestToken is ERC20, Ownable2Step, ERC20Capped,ReentrancyGuard {
    
    constructor(String memory tokenName, String memory tokenSymbol, uint256 cap,uint256 initialAmount )
        // ERC20("MyTestToken", "MTTK")
        // ERC20Capped(1_000_001 * 10 ** decimals())
        // Ownable(msg.sender)
        ERC20(tokenName, tokenSymbol)
        ERC20Capped(cap * 10 ** decimals())
        Ownable(msg.sender)
    {
        _mint(msg.sender, initialAmount * 10 ** decimals());
    }

    function _update(address from, address to, uint256 value) internal
        override(ERC20, ERC20Capped)
    {        
        //can only override virtual functions
        // if(from != address(0)){
        //     require(balanceOf(from) >= 1000 * 10 ** decimals(), "balance less than 1000");
        // }
        super._update(from, to, value);
    }

    //security testing done

    function mint(address to, uint256 amount) public onlyOwner nonReentrant  {
        _mint(to, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}