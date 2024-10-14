// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SampleToken is ERC20, Ownable {
    // Constructor to set the token details
    constructor(string memory name, string memory symbol, uint256 totalSupply) ERC20(name, symbol) Ownable(msg.sender)
    {
        // Mint the initial total supply to the deployer
        _mint(msg.sender, totalSupply * (10 ** decimals()));
    }

    // Mint function to allow the owner to mint new tokens
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}