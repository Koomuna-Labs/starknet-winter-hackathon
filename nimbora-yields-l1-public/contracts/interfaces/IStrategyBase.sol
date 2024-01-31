// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

uint256 constant DEPOSIT = 0;
uint256 constant REPORT = 1;
uint256 constant WITHDRAW = 2;

interface IStrategyBase {
    function initializeStrategyBase(address _l2PoolingManager, address _underlyingToken, address _yieldToken) external;

    function handleReport(uint256 actionId, uint256 amount) external payable returns (uint256, uint256);

    function nav() external view returns (uint256);

    function yieldToUnderlying(uint256 amount) external view returns (uint256);

    function underlyingToYield(uint256 amount) external view returns (uint256);

    function yieldBalance() external view returns (uint256);

    function poolingManager() external view returns (address);
}
