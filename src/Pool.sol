// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Pool {

    uint total_token_nums; 
    address[] tokens; 
    uint total_supply; 
    uint[] reserve;
    uint sigma; 
    uint eta; 


    constructor( address[] memory tokens_, uint total_token_nums_,  uint sigma_, uint eta_)
    {
        sigma = sigma_; 
        eta = eta_; 
        tokens = tokens_; 
        total_token_nums = total_token_nums_; 
        
    }
    

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


    function Ufun(uint[] memory assetArr) public view returns(uint)
    {
        require(assetArr.length >= 3);
        uint a = assetArr[0]; 
        uint b = assetArr[1]; 
        uint y = assetArr[2];
        uint x = (a ** (1 - sigma) + b ** (1 - sigma)) ** (1 / (1 - sigma));
        uint U = x ** (1 - eta) + y ** (1 - eta); 
        return U; 


    } 

    function diff(uint[] memory reserveArr, uint[] memory changeInReserveArr) public view returns(uint){
        uint UStart = Ufun(reserveArr);  
        uint UChange = Ufun(changeInReserveArr); 
        return UChange - UStart; 
    } 

    function calcTokensToRelease( uint indexOfTokenGiven,  uint amountOfTokenGiven, uint indexOfTargetToken ) public returns(uint){
 
        uint[] memory incomingAssets = new uint[](total_token_nums);
        incomingAssets[indexOfTokenGiven] = amountOfTokenGiven; 

        uint[] memory changeInReserveArr = new uint[](total_token_nums);

        require(reserve.length == changeInReserveArr.length); 

        for (uint i=0; i< reserve.length; i++) {
            changeInReserveArr[i] = reserve[i] + incomingAssets[i]; 
        }


        uint x0 = amountOfTokenGiven; 
        uint k = indexOfTargetToken;     

        while (( uint(abs( int(diff(reserve, changeInReserveArr))) * (1**10))) > 1){

            sigma = sigma/100; 
            eta = eta/100; 
            uint y0 = diff(reserve, changeInReserveArr); 
            //incomingAssets[k] += 0.1; 
            uint x1 = incomingAssets[k]; 
            uint y1 = diff(reserve, changeInReserveArr); 
            uint deriv = 100 * (y1 - y0) / (x1 - x0); 
            x0 -= (y0 / deriv); 
            incomingAssets[k] = x0; 

        }

        return 0; 

    }

    function abs(int x) private pure returns (int) 
    {
    return x >= 0 ? x : -x;
    }

    
}
