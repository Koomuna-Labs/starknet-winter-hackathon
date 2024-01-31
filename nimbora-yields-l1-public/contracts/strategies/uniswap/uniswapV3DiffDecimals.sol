// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {ErrorLib} from "../../lib/ErrorLib.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {UniswapV3Strategy} from "./uniswapV3.sol";

contract UniswapV3StrategyDiffDecimals is UniswapV3Strategy {
    uint256 public underlyingTokenPrecision;
    uint256 public yieldTokenPrecision;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _l2PoolingManager,
        address _underlyingToken,
        address _yieldToken,
        address _uniswapRouter,
        address _uniswapFactory,
        address _chainlinkPricefeed,
        uint256 _minReceivedAmountFactor,
        uint24 _poolFee
    ) public override initializer {
        UniswapV3Strategy.initialize(
            _l2PoolingManager,
            _underlyingToken,
            _yieldToken,
            _uniswapRouter,
            _uniswapFactory,
            _chainlinkPricefeed,
            _minReceivedAmountFactor,
            _poolFee
        );
    }

    function _checkDecimals(address _underlyingToken, address _yieldToken) internal override {
        uint8 underlyingTokenDecimals = IERC20Metadata(_underlyingToken).decimals();
        uint8 yieldTokenDecimals = IERC20Metadata(_yieldToken).decimals();
        if (underlyingTokenDecimals == yieldTokenDecimals) revert ErrorLib.InvalidDecimals();
        underlyingTokenPrecision = 10 ** uint256(underlyingTokenDecimals);
        yieldTokenPrecision = 10 ** uint256(yieldTokenDecimals);
    }

    function _calculateUnderlyingToYieldAmount(
        uint256 yieldPrice,
        uint256 amount
    ) internal view override returns (uint256) {
        return (pricefeedPrecision * yieldTokenPrecision * amount) / (yieldPrice * underlyingTokenPrecision);
    }

    function _calculateYieldToUnderlyingAmount(
        uint256 yieldPrice,
        uint256 amount
    ) internal view override returns (uint256) {
        return (amount * yieldPrice * underlyingTokenPrecision) / (pricefeedPrecision * yieldTokenPrecision);
    }
}
