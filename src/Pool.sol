// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "PRBMath/PRBMathUD60x18.sol";
import "./LPToken.sol";

// remix 
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "prb-math/contracts/PRBMathUD60x18.sol";


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
    uint256 id;


    LPToken lpToken;

    uint public constant MINIMUM_LIQUIDITY = 10**3;

    event addedLiquidityEvent(uint256 id, address user, uint256[] amountsArr, uint256 LPGiven);
    event newPoolEvent(string poolName, string poolTicker, uint256 poolId, address LPTokenAddr, address poolAddress, address[] tokenAddresses, uint256 sigma, uint256 eta);

    constructor(uint256 _id, string memory poolName, string memory poolTicker, address[] memory tokens_, uint total_token_num_,  uint sigma_, uint eta_)
    {
       require(total_token_num_ == tokens_.length); 
       id = _id;
        _sigma = sigma_; 
        _eta = eta_; 
        tokens = tokens_; 
        total_token_nums = total_token_num_; 
        lpToken = new LPToken(poolName, poolTicker); // LP Token's address
        reserve = new uint[](total_token_nums); 
         emit newPoolEvent(poolName, poolTicker, id, address(lpToken), address(this), tokens, _sigma, _eta);
    }

    // constructor()
    // {
        
    //     _sigma = 99; 
    //     _eta = 2;
    //     tokens = [0x9D549699f410EE213DbbAD831920A2fE724b6654, 0x2bd63E94E32b9Bc88eE07adE60FE73224316D7ba, 0x2233825a5CFFC9552869d12C94F0e3fcCC194ae3]; // all OOO
    //     total_token_nums = 3;
    //     lpToken = new LPToken("LPToken", "LPT"); // LP Token's address 
    //     reserve = new uint[](total_token_nums); 
    // }


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



    function mint(uint[] memory amounts) public returns (uint) {
        require(amounts.length == total_token_nums);
        // [2100000000000000000,  2000000000000000000]
        uint LPamount = 0; 

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

        else{
            for (uint i=0; i<total_token_nums; i++) {
                IERC20 token = IERC20(tokens[i]); 
                token.transferFrom(msg.sender, address(this), amounts[i]); 
                // sends from your wallet to contract 
                LPamount +=  unsignedDiv( unsignedMul( amounts[i] , (total_supply * (10**18)) ) , reserve[i]) ;  
                reserve[i] += amounts[i];
                total_supply += amounts[i];
            }   
        }
        lpToken.mint(address(this), LPamount); 
        emit addedLiquidityEvent(id, msg.sender, amounts, LPamount);
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

        return x0; 

    }

    function swap(int indexOfTokenGiven,  uint amountOfTokenGiven, uint indexOfTargetToken) public {
        //Transfer users tokens to the contract
        //amountToRelease = calcTokensToRelease
        //reserves[indexOfTargetToken] -= amountToRelease
        //Transfer amountToRelease to user
    }

    function abs(int x) private pure returns (int) 
    {
    return x >= 0 ? x : -x;
    }


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

    function unsignedSqrt(uint256 x) public pure returns (uint256 result){
        return PRBMathUD60x18.sqrt(x);
    }

    function unsignedDiv(uint256 x, uint256 y) public pure returns (uint256 result) {
        result = PRBMathUD60x18.div(x,y); 
        return result;
    }
}