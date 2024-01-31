// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

interface IChainlinkAggregator {
    /**
     * @notice Reads the current answer from aggregator delegated to.
     */
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint8);
}
