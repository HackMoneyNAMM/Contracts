// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
//import * as math from  "./UnsignedConsumer.sol";
import "PRBMath/PRBMathUD60x18.sol";

contract Pool {
    using PRBMathUD60x18 for uint256;

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
        uint x = ( unsignedPow(a , (1-sigma)) + unsignedPow(unsignedPow(b , (1 - sigma)) , unsignedDiv(1 , (1 - sigma))));
        uint U = unsignedPow(x , (1 - eta)) +  unsignedPow(y,  (1 - eta)); 
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

            sigma = unsignedDiv(sigma, 100); 
            eta =  unsignedDiv(eta, 100); 
            uint y0 = diff(reserve, changeInReserveArr); 
            incomingAssets[k] += unsignedDiv(1,10); 
            uint x1 = incomingAssets[k]; 
            uint y1 = diff(reserve, changeInReserveArr); 
            uint deriv = unsignedMul(100 ,  unsignedDiv((y1 - y0) , (x1 - x0))); 
            x0 -= unsignedDiv(y0 , deriv); 
            incomingAssets[k] = x0; 

        }

        return 0; 

    }

    function abs(int x) private pure returns (int) 
    {
    return x >= 0 ? x : -x;
    }

      /// @dev Note that "y" is a basic uint256 integer, not a fixed-point number.
  function unsignedPow(uint256 x, uint256 y) public pure returns (uint256 result) {
    result = x.pow(y);
  }

     function unsignedDiv(uint256 x, uint256 y) public pure returns (uint256 result) {
    result = x.div(y);
  }

    /// @notice Calculates x*y÷1e18 while handling possible intermediary overflow.
  /// @dev Try this with x = type(uint256).max and y = 5e17.
  function unsignedMul(uint256 x, uint256 y) public pure returns (uint256 result) {
    result = PRBMathUD60x18.mul(x, y);
  }


    
}
