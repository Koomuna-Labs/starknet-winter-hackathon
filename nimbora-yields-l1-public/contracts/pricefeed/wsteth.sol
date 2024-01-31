// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainlinkAggregator} from "../interfaces/IChainlinkAggregator.sol";
import {IWstETH} from "../interfaces/IWstETH.sol";

/// @title wstETH/ETH price feed compatible with AAVE feed interface.
/// @dev Please notice that this feed doesn't provide the complete Chainlink feed interface.
contract AAVECompatWstETHToETHPriceFeed is IChainlinkAggregator {
    IWstETH public immutable wstETH;
    IChainlinkAggregator public immutable stETHToETHPriceFeed;

    int256 internal constant PRECISION = 10 ** 18;

    constructor(address _stETHToETHPriceFeed, address _wstETH) {
        stETHToETHPriceFeed = IChainlinkAggregator(_stETHToETHPriceFeed);
        wstETH = IWstETH(_wstETH);
    }

    /**
     * @notice Get price of one wstETH expressed in ETH.
     */
    function latestAnswer() external view override returns (int256) {
        int256 wstETHToStETH = int256(wstETH.stEthPerToken());
        assert(wstETHToStETH > 0);
        int256 stETHToETH = stETHToETHPriceFeed.latestAnswer();

        return (wstETHToStETH * stETHToETH) / PRECISION;
    }

    function decimals() external pure override returns (uint8) {
        return (18);
    }

    /**
     * @notice Revert all calls except the 'latestAnswer'
     */
    fallback() external {
        revert("Unexpected function call.");
    }
}
