pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";

contract LPToken is ERC20, Ownable{
    constructor(string memory tokenName, string memory tokenTicker) ERC20(tokenName, tokenTicker) {
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}