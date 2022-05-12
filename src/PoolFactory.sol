// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Pool.sol";

contract PoolFactory {

    event newPoolEvent(uint256, address, address[]);

    uint256 poolIdCntr = 0;

    //poolId => Pool
    mapping(uint256 => PoolStruct) pools;

    struct PoolStruct {
        uint256 id;
        address addr;
        address[] tokens;
    }

    function newPool(address[] memory tokens) public returns (address poolAddr){

        //I don't like this, but its almost necessary....
        for (uint256 i=0; i<tokens.length; i++){
            for(uint256 j=0; j<tokens.length; j++){
                if(tokens[i] != tokens[j]){
                    require(tokens[i] != tokens[j], "Cannot create a pool with two identical tokens in it!");
                }
            }
            require(tokens[i] != address(0));
        }

        Pool deployedPool = new Pool();

        PoolStruct memory pool;
        pool.id = poolIdCntr;
        pool.addr = address(deployedPool);
        pool.tokens = tokens;

        pools[poolIdCntr] = pool;
        poolIdCntr++;
        
        emit newPoolEvent(pool.id, pool.addr, pool.tokens);
        return address(deployedPool);
    }

}