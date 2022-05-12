// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Pool {

    uint total_token_nums; 
    address[] tokens; 
    uint total_supply; 
    uint[] reserve; 


    function mint(uint[] memory amounts) public returns (uint) {

        require(amounts.length == total_token_nums);
        uint LPamount = 0; 
        for (uint i=0; i<total_token_nums; i++) {
            IERC20 token = IERC20(tokens[i]); 
            token.transferFrom(msg.sender, address(this), amounts[i]); 
            LPamount +=  ( amounts[i] * total_supply ) / reserve[i] ; 
            reserve[i] += amounts[i];
        }

        //mint(LPamount, address(this)); 
        return LPamount; 

    }
    
}
