// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {StrategyBase} from "../StrategyBase.sol";
import {IChainlinkAggregator} from "../../interfaces/IChainlinkAggregator.sol";
import "../../interfaces/IStrategyUniswapV3.sol";
import {ErrorLib} from "../../lib/ErrorLib.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

contract UniswapV3Strategy is StrategyBase {
    ISwapRouter public uniswapRouter;
    IChainlinkAggregator public chainlinkPricefeed;
    uint256 public pricefeedPrecision;
    uint256 public minReceivedAmountFactor;
    uint24 public poolFee;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _poolingManager,
        address _underlyingToken,
        address _yieldToken,
        address _uniswapRouter,
        address _uniswapFactory,
        address _chainlinkPricefeed,
        uint256 _minReceivedAmountFactor,
        uint24 _poolFee
    ) public virtual initializer {
        initializeStrategyBase(_poolingManager, _underlyingToken, _yieldToken);
        _initializeUniswap(_uniswapRouter, _uniswapFactory, _underlyingToken, _yieldToken, _poolFee);
        _initializeChainlink(_chainlinkPricefeed);
        _setSlippage(_minReceivedAmountFactor);
        _checkDecimals(_underlyingToken, _yieldToken);
    }

    function setMinReceivedAmountFactor(uint256 _minReceivedAmountFactor) public {
        _assertOnlyRoleOwner();
        _setSlippage(_minReceivedAmountFactor);
    }

    function chainlinkLatestAnswer() public view returns (int256) {
        return _chainlinkLatestAnswer();
    }

    function applySlippageDepositExactInputSingle(uint256 amount) public view returns (uint256) {
        return _applySlippageDepositExactInputSingle(amount);
    }

    function applySlippageWithdrawExactOutputSingle(uint256 amount) public view returns (uint256) {
        return _applySlippageWithdrawExactOutputSingle(amount);
    }

    function _initializeUniswap(
        address _uniswapRouterAddress,
        address _uniswapFactoryAddress,
        address _underlyingToken,
        address _yieldToken,
        uint24 _poolFee
    ) internal {
        require(_uniswapRouterAddress != address(0), "Zero address: Uniswap Router");
        uniswapRouter = ISwapRouter(_uniswapRouterAddress);

        IUniswapV3Factory uniswapFactory = IUniswapV3Factory(_uniswapFactoryAddress);
        address poolAddress = uniswapFactory.getPool(_underlyingToken, _yieldToken, _poolFee);
        require(poolAddress != address(0), "Pool does not exist");
        poolFee = _poolFee;

        IERC20(_underlyingToken).approve(_uniswapRouterAddress, type(uint256).max);

        IERC20(_yieldToken).approve(_uniswapRouterAddress, type(uint256).max);
    }

    function _initializeChainlink(address chainlinkPricefeedAddress) internal {
        require(chainlinkPricefeedAddress != address(0), "Zero address: Chainlink");
        chainlinkPricefeed = IChainlinkAggregator(chainlinkPricefeedAddress);
        pricefeedPrecision = 10 ** chainlinkPricefeed.decimals();
    }

    function _setSlippage(uint256 _minReceivedAmountFactor) internal {
        require(
            _minReceivedAmountFactor <= SLIPPAGE_PRECISION &&
                _minReceivedAmountFactor >= (SLIPPAGE_PRECISION * 95) / 100,
            "Invalid slippage"
        );
        minReceivedAmountFactor = _minReceivedAmountFactor;
    }

    function _checkDecimals(address _underlyingToken, address _yieldToken) internal virtual {
        if (IERC20Metadata(_underlyingToken).decimals() != IERC20Metadata(_yieldToken).decimals())
            revert ErrorLib.InvalidDecimals();
    }

    function _deposit(uint256 amount) internal override {
        uint256 yieldAmount = _underlyingToYield(amount);
        uint256 amountOutMinimum = _applySlippageDepositExactInputSingle(yieldAmount);
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: underlyingToken,
            tokenOut: yieldToken,
            fee: poolFee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amount,
            amountOutMinimum: amountOutMinimum,
            sqrtPriceLimitX96: 0
        });

        uniswapRouter.exactInputSingle(params);
    }

    function _withdraw(uint256 amount) internal override returns (uint256) {
        uint256 chainlinkLatestAnswer = uint256(_chainlinkLatestAnswer());
        uint256 yieldAmount = _calculateUnderlyingToYieldAmount(chainlinkLatestAnswer, amount);
        uint256 amountInMaximum = _applySlippageWithdrawExactOutputSingle(yieldAmount);
        uint256 yieldBalance = yieldBalance();

        if (amountInMaximum > yieldBalance) {
            uint256 underlyingAmount = _calculateYieldToUnderlyingAmount(chainlinkLatestAnswer, yieldBalance);
            uint256 amountOutMinimum = _applySlippageDepositExactInputSingle(underlyingAmount);
            ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
                tokenIn: yieldToken,
                tokenOut: underlyingToken,
                fee: poolFee,
                recipient: poolingManager,
                deadline: block.timestamp,
                amountIn: yieldBalance,
                amountOutMinimum: amountOutMinimum,
                sqrtPriceLimitX96: 0
            });
            uint256 output = uniswapRouter.exactInputSingle(params);
            return (output);
        } else {
            ISwapRouter.ExactOutputSingleParams memory params = ISwapRouter.ExactOutputSingleParams({
                tokenIn: yieldToken,
                tokenOut: underlyingToken,
                fee: poolFee,
                recipient: poolingManager,
                deadline: block.timestamp,
                amountOut: amount,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });
            uniswapRouter.exactOutputSingle(params);
            return (amount);
        }
    }

    function _applySlippageDepositExactInputSingle(uint256 amount) internal view returns (uint256) {
        return (minReceivedAmountFactor * amount) / (SLIPPAGE_PRECISION);
    }

    function _applySlippageWithdrawExactOutputSingle(uint256 amount) internal view returns (uint256) {
        return (SLIPPAGE_PRECISION * amount) / (minReceivedAmountFactor);
    }

    function _chainlinkLatestAnswer() internal view returns (int256) {
        return chainlinkPricefeed.latestAnswer();
    }

    function _underlyingToYield(uint256 amount) internal view override returns (uint256) {
        return _calculateUnderlyingToYieldAmount(uint256(_chainlinkLatestAnswer()), amount);
    }

    function _yieldToUnderlying(uint256 amount) internal view override returns (uint256) {
        return _calculateYieldToUnderlyingAmount(uint256(_chainlinkLatestAnswer()), amount);
    }

    function _calculateUnderlyingToYieldAmount(
        uint256 yieldPrice,
        uint256 amount
    ) internal view virtual returns (uint256) {
        return (pricefeedPrecision * amount) / (yieldPrice);
    }

    function _calculateYieldToUnderlyingAmount(
        uint256 yieldPrice,
        uint256 amount
    ) internal view virtual returns (uint256) {
        return (amount * yieldPrice) / (pricefeedPrecision);
    }
}
