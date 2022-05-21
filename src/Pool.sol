// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "PRBMath/PRBMathUD60x18.sol";
import "./LPToken.sol";

contract Pool {
    using PRBMathUD60x18 for uint256;

    uint total_token_nums; 
    address[] tokens; 
    uint total_supply; 
    uint[] reserve;
    uint _sigma; 
    uint _eta; 

    LPToken lpToken;

    uint public constant MINIMUM_LIQUIDITY = 10**3;

    event addedLiquidityEvent(address user, uint256[] amountsArr, uint256 LPGiven);

    constructor(address tokenAddress, address[] memory tokens_, uint total_token_num_,  uint sigma_, uint eta_)
    {
        _sigma = sigma_; 
        _eta = eta_; 
        tokens = tokens_; 
        total_token_nums = total_token_num_; 
        lpToken = LPToken(tokenAddress);
    }
    

    function mint(uint[] memory amounts) public returns (uint) {
        require(amounts.length == total_token_nums);

        uint LPamount = 0; 

        if(total_supply == 0){
            uint256 amountProduct = 0;
            for(uint256 i=0; i<total_token_nums; i++){
                if(i==0){
                    amountProduct=amounts[0];
                }
                else{
                    amountProduct=unsignedMul(amountProduct, amounts[i]);
                }
                total_supply += amounts[i];
            }
            uint256 rootedAmount = unsignedPow(amountProduct, unsignedDiv(1, total_token_nums));
            LPamount = rootedAmount-MINIMUM_LIQUIDITY;
            lpToken.mint(address(0), MINIMUM_LIQUIDITY);
        }

        else{
            for (uint i=0; i<total_token_nums; i++) {
                IERC20 token = IERC20(tokens[i]); 
                token.transferFrom(msg.sender, address(this), amounts[i]); 
                LPamount +=  ( amounts[i] * total_supply ) / reserve[i] ; 
                reserve[i] += amounts[i];
                total_supply += amounts[i];
            }   

            
        }
        lpToken.mint(address(this), LPamount); 
        
        emit addedLiquidityEvent(msg.sender, amounts, LPamount);
        return LPamount; 

    }


    function Ufun(uint[] memory assetArr) public view returns(uint)
    {
        uint256 sigma = unsignedDiv(_sigma, 100);
        uint256 eta = unsignedDiv(_eta, 100);

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

    function calcTokensToRelease( uint indexOfTokenGiven,  uint amountOfTokenGiven, uint indexOfTargetToken ) public view returns(uint){
 
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
        return result;
    }

    function unsignedDiv(uint256 x, uint256 y) public pure returns (uint256 result) {
        result = x.div(y);
        return result;
    }

    /// @notice Calculates x*y÷1e18 while handling possible intermediary overflow.
    /// @dev Try this with x = type(uint256).max and y = 5e17.
    function unsignedMul(uint256 x, uint256 y) public pure returns (uint256 result) {
        result = PRBMathUD60x18.mul(x, y);
        return result;
    }  

    function sqrt(uint256 x) public pure returns (uint256 result){
        return PRBMathUD60x18.sqrt(x);
    }
}
