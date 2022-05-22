
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
//import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "PRBMath/PRBMathUD60x18.sol";
//import "prb-math/contracts/PRBMathUD60x18.sol";
import "./LPToken.sol";

contract Pool {
    using PRBMathUD60x18 for uint256;

    uint total_token_nums; 
    address[] tokens; 
    uint total_supply; 
    uint[] reserve;
    uint _sigma; 
    uint _eta; 
    uint amounts_product; // TESTING 
    uint rooted_amount; // TESTING 
    uint _U; 


    LPToken lpToken;

    uint public constant MINIMUM_LIQUIDITY = 10**3;

    event addedLiquidityEvent(uint256 id, address user, uint256[] amountsArr, uint256 LPGiven);
    event newPoolEvent(string poolName, string poolTicker, uint256 poolId, address LPTokenAddr, address poolAddress, address[] tokenAddresses, uint256 sigma, uint256 eta);

    constructor(address tokenAddress, address[] memory tokens_, uint total_token_num_,  uint sigma_, uint eta_)
    {
       require(total_token_num_ == 3); 
        _sigma = sigma_; 
        _eta = eta_; 
        tokens = tokens_; 
        total_token_nums = total_token_num_; 
        lpToken = new LPToken(poolName, poolTicker); // LP Token's address
        reserve = new uint[](total_token_nums); 
         emit newPoolEvent(poolName, poolTicker, id, address(lpToken), address(this), tokens, _sigma, _eta);
    }

    
    // Just for testing with Remix 
    function mintTest(uint[] memory arr) public returns(uint){
        for (uint i=0; i<arr.length; i++) {
            arr[i] = arr[i] * (10**18); 
            
        } 
        return mint(arr); 
    }

    function getTokenBalance() public view returns(uint[] memory){
       
        uint[] memory tokens_bal = new uint[](3);  
        for (uint i=0; i<tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]); 
            tokens_bal[i] = token.balanceOf(msg.sender); 
        }
        return tokens_bal; 

        // iterate over tokens in contract and get the balance of them and put them in new array 

    }

    // GOOD 
    function mint(uint[] memory amounts) public returns (uint) {
        require(amounts.length == total_token_nums);
        // [2100000000000000000,  2000000000000000000]
        uint LPamount = 0; 

        // EQUAl OK 
        // NOT EQUAL 

        if(total_supply == 0){
            uint256 amountProduct = 0;
            for(uint256 i=0; i<total_token_nums; i++){
                if(i==0){
                    amountProduct=amounts[0];
                }
                else{
                    amountProduct= unsignedMul(amountProduct, amounts[i]);
                }
                total_supply += amounts[i];
                IERC20 token = IERC20(tokens[i]); 
                token.transferFrom(msg.sender, address(this), amounts[i]); 
                reserve[i] += amounts[i]; 

            }

            amounts_product = amountProduct; 
            uint256 rootedAmount = unsignedPow(amountProduct, unsignedDiv((10**18), (total_token_nums * (10**18))));
            rooted_amount = rootedAmount; 
            LPamount = rootedAmount-MINIMUM_LIQUIDITY;
        }

        // EQUAl OK 
        // NOT EQUAL 

        else{
            // NOT TESTED
            uint added = 0; 
            for (uint i=0; i<total_token_nums; i++) {
                IERC20 token = IERC20(tokens[i]); 
                token.transferFrom(msg.sender, address(this), amounts[i]); 
                // sends from your wallet to contract 
                                             // (5     *          15  ) /  5  
                LPamount +=  unsignedDiv( unsignedMul( amounts[i] , total_supply)  , reserve[i]) ;  
                reserve[i] += amounts[i];
                added += amounts[i]; 

                
            }   
            total_supply += added; 
        }
        lpToken.mint(msg.sender, LPamount); 
        emit addedLiquidityEvent(id, msg.sender, amounts, LPamount);
        return LPamount;    

    }

    // Just for testing with Remix 
    function UfunTest(uint[] memory arr) public view returns(uint){
        for (uint i=0; i<arr.length; i++) {
            arr[i] = arr[i] * (10**18); 
            
        } 
        return Ufun(arr); 
    }

    // GOOD 
    function Ufun(uint[] memory assetArr) public view returns(uint)
    {
        uint256 sigma = unsignedDiv(_sigma, 100);
        uint256 eta = unsignedDiv(_eta, 100);

        require(assetArr.length >= 3);
        uint a = assetArr[0]; 
        uint b = assetArr[1]; 
        uint y = assetArr[2];
        uint x = ( unsignedPow(a , ((10**18)-sigma)) + unsignedPow(unsignedPow(b , ((10**18) - sigma)) , unsignedDiv((10**18), ((10**18)- sigma))));
        uint U = unsignedPow(x , ((10**18)- eta)) +  unsignedPow(y,  ((10**18)- eta)); 
        // setU(U);
        return U; 
    } 

    // GOOD PROBABLY 
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
            changeInReserveArr[i] = reserve[i] + incomingAssets[i]; }
        uint x0 = amountOfTokenGiven; 
        uint k = indexOfTargetToken;     


        while (( uint(abs( int(diff(reserve, changeInReserveArr))) * (1**10))) > 1){
            uint y0 = diff(reserve, changeInReserveArr); 
            incomingAssets[k] += unsignedDiv(1*(10**18), 10*(10**18)); 
            uint x1 = incomingAssets[k]; 
            uint y1 = diff(reserve, changeInReserveArr); 
            uint deriv = unsignedMul(100 * (10**18) ,  unsignedDiv((y1 - y0) , (x1 - x0))); 
            x0 -= unsignedDiv(y0 , deriv); 
            incomingAssets[k] = x0; 
        }

        return x0; 

    }


    function swap(uint indexOfTokenGiven,  uint amountOfTokenGiven, uint indexOfTargetToken ) public  returns(uint){
        uint amountToRelease = calcTokensToRelease( indexOfTokenGiven,  amountOfTokenGiven, indexOfTargetToken ); 

        // user to contract 
        IERC20 token1 = IERC20(tokens[indexOfTokenGiven]); 
        token1.transferFrom(  msg.sender, address(this), amountOfTokenGiven  * (10**18) ); 
        // allowance to address(this)

        // contract to user 
        ERC20 token = ERC20(tokens[indexOfTargetToken]); 
        //token.increaseAllowance(msg.sender, amountToRelease); 
        //require() contract must have amount to release 
        token.transfer( msg.sender, amountToRelease * (10**18) ); 

        reserve[indexOfTargetToken] -= amountToRelease; 
        return amountToRelease;
    }


    function abs(int x) private pure returns (int) 
    {
    return x >= 0 ? x : -x;
    }

    // function unsignedbs(uint256 x) public pure returns (uint256 result) {
    //     result = PRBMathUD60x18.abs(x);
    //     return result;
    // }  


    // NOT WORKING 
        /// @notice Calculates x*y÷1e18 while handling possible intermediary overflow.
        /// @dev Try this with x = type(uint256).max and y = 5e17.
    function unsignedMul(uint256 x, uint256 y) public pure returns (uint256 result) {
        result = PRBMathUD60x18.mul(x, y);
        return result;
    }  

        /// @dev Note that "y" is a basic uint256 integer, not a fixed-point number.
    function unsignedPow(uint256 x, uint256 y) public pure returns (uint256 result) {
        result = PRBMathUD60x18.pow(x,y);
        return result;
    }

    // WORKING 
    function unsignedSqrt(uint256 x) public pure returns (uint256 result){
        return PRBMathUD60x18.sqrt(x);
    }

    function unsignedDiv(uint256 x, uint256 y) public pure returns (uint256 result) {
        result = PRBMathUD60x18.div(x,y); 
        return result;
    }

    function getU() public view returns(uint){
        return _U;
    }

    function setU(uint U) public {
        _U = U; 
    }


    function getLPTokenAddr() public view returns(address){
        return address(lpToken);
    }


    function getTotalTokenNums() public view returns (uint){
        return total_token_nums;
    }

    function getTokens() public view returns ( address[] memory){
        return tokens;
    }

    function getTotalSupply() public view returns (uint){
        return total_supply; 
    }

    function getReserve() public view returns ( uint[] memory){
        return reserve;
    }

    function getSigma() public view returns (uint){
        return _sigma; 
    }

    function getEta() public view returns (uint){
        return _eta;
    }
    
    function getAmountProduct() public view returns (uint){
        return amounts_product;
    }

    function getRootedAmount() public view returns (uint){
        return rooted_amount; 
    }

}
