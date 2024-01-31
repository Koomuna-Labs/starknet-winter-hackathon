// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

contract UniswapV3FactoryMock {
    mapping(address => mapping(address => mapping(uint24 => address))) public pools;

    function setPool(address tokenA, address tokenB, uint24 fee, address pool) public {
        pools[tokenA][tokenB][fee] = pool;
        pools[tokenB][tokenA][fee] = pool;
    }

    function getPool(address tokenA, address tokenB, uint24 fee) external view returns (address) {
        return pools[tokenA][tokenB][fee];
    }
}
