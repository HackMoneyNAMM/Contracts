// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Pool.sol";

contract PoolFactory {

    event newPoolEvent(string poolName, string poolTicker, uint256 poolId, address lpTokenAddress, address poolAddress, address[] tokenAddresses, uint256 sigma, uint256 eta);

    uint256 poolIdCntr = 0;

    //poolId => Pool
    mapping(uint256 => PoolStruct) pools;

    struct PoolStruct {
        uint256 id;
        address addr;
        address[] tokens;
        address tokenAddr;
    }

    function newPool(string memory poolName, string memory poolTicker, address[] memory tokens, uint256 sigma, uint256 eta) public returns (address poolAddr){

        //I don't like this, but its almost necessary....
        for (uint256 i=0; i<tokens.length; i++){
            for(uint256 j=0; j<tokens.length; j++){
                if(tokens[i] != tokens[j]){
                    require(tokens[i] != tokens[j], "Cannot create a pool with two identical tokens in it!");
                }
            }
            require(tokens[i] != address(0));
        }

        //LPToken lpToken = new LPToken(poolName, poolTicker); Have to 
        Pool deployedPool = new Pool(poolIdCntr, poolName, poolTicker, tokens, tokens.length, sigma, eta);

        PoolStruct memory pool;
        pool.id = poolIdCntr;
        pool.addr = address(deployedPool);
        pool.tokens = tokens;

        pools[poolIdCntr] = pool;
        poolIdCntr++;
        
        emit newPoolEvent(poolName, poolTicker, pool.id, pool.tokenAddr, pool.addr, pool.tokens, sigma, eta);
        return address(deployedPool);
    }

}
