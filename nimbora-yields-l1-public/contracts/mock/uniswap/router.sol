// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMinimalSwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);
}

contract UniswapRouterMock is IMinimalSwapRouter {
    uint256 private constant PRECISION = 1e18;

    // Exchange rates with precision
    mapping(address => mapping(address => uint256)) public exchangeRates;

    function setExchangeRate(address tokenIn, address tokenOut, uint256 rate) public {
        exchangeRates[tokenIn][tokenOut] = rate;
        exchangeRates[tokenOut][tokenIn] = PRECISION ** 2 / rate;
    }

    function exactInputSingle(
        ExactInputSingleParams calldata params
    ) external payable override returns (uint256 amountOut) {
        require(IERC20(params.tokenIn).transferFrom(msg.sender, address(this), params.amountIn), "Transfer failed");

        amountOut = (params.amountIn * exchangeRates[params.tokenIn][params.tokenOut]) / PRECISION;
        require(amountOut >= params.amountOutMinimum, "Insufficient output amount");
        require(IERC20(params.tokenOut).transfer(params.recipient, amountOut), "Transfer failed");

        return amountOut;
    }

    function exactOutputSingle(
        ExactOutputSingleParams calldata params
    ) external payable override returns (uint256 amountIn) {
        // Calculate amountIn with precision
        amountIn = (params.amountOut * PRECISION) / exchangeRates[params.tokenIn][params.tokenOut];
        require(amountIn <= params.amountInMaximum, "Excessive input amount");

        require(IERC20(params.tokenIn).transferFrom(msg.sender, address(this), amountIn), "Transfer failed");

        require(IERC20(params.tokenOut).transfer(params.recipient, params.amountOut), "Transfer failed");
        return amountIn;
    }
}
