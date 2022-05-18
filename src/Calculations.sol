//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.5.0 <0.9.0;
 
contract Calculations{
    

   // removing the last element of the array
    function Ufun(uint[] memory assetArr, uint sigma, uint eta,  uint y ) public view returns(uint){
        require(assetArr.length >= 3);
        uint a = assetArr[0]; 
        uint b = assetArr[1]; 
        uint c = assetArr[2]; 

        // question: What are x and y
        // should y be passed in? 

        uint x = (a ** (1 - sigma) + b ** (1 - sigma)) ** (1 / (1 - sigma));
        uint U = x ** (1 - eta) + y ** (1 - eta); 
        return U; 


    } 

    function diff(uint[] memory reserveArr, uint[] memory changeInReserveArr, uint sigma, uint eta) public view returns(uint){
        uint UStart = Ufun(reserveArr, sigma, eta, 0);  
        uint UChange = Ufun(changeInReserveArr, sigma, eta, 0); 
        // default 0 for y this is probably wrong, not sure if sigma and eta should be the same 
        return UChange - UStart; 

    } 

    function calcTokensToRelease() public view returns(uint){
        return 0; 


        uint indexOfTokenGiven = 0; 
        uint amountOfTokenGiven = 10; 
        uint indexOfTargetToken = 2; 

        uint sigma = 99; //divide by 100
        uint eta = 2; 

        //Incoming assets being traded
        uint[] memory incomingAssets = new uint[](3);
        incomingAssets[0] = 10;
        incomingAssets[1] = 10;
        incomingAssets[2] = 10;
        incomingAssets[indexOfTokenGiven] = amountOfTokenGiven; 

        uint[] memory reserves = new uint[](3);
        reserves[0] = 10;
        reserves[1] = 10;
        reserves[2] = 10;

        uint[] memory changeInReserveArr = new uint[](3);

        require(reserves.length == changeInReserveArr.length); 

        for (uint i=0; i< reserves.length; i++) {
            changeInReserveArr[i] = reserves[i] + incomingAssets[i]; 
        }

        string[] memory tokens = new string[](3); 
        tokens[0] = "cUSDAddr"; 
        tokens[1] =  "USDCAddr"; 
        tokens[2] =   "ETHAddr"; 

        uint x0 = amountOfTokenGiven; 
        uint k = indexOfTargetToken;     

        while (abs(diff(reserves, changeInReserveArr, sigma, eta)) > 1e-10){

            sigma = sigma/100; 
            eta = eta/100; 
            uint y0 = diff(reserves, changeInReserveArr, sigma, eta); 
            incomingAssets[k] += 1e-1; 
            uint x1 = incomingAssets[k]; 
            uint y1 = diff(reserves, changeInReserveArr, sigma, eta); 
            uint deriv = 100 * (y1 - y0) / (x1 - x0); 
            x0 -= (y0 / deriv); 
            incomingAssets[k] = x0; 

        }

        return 0; 

    }

    function abs(int x) private pure returns (int) {
    return x >= 0 ? x : -x;
}


}
