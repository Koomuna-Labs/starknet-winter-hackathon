// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "../../strategies/StrategyBase.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Extended is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

contract TestStrategyBase is StrategyBase {
    uint256 private _yieldFactor;
    uint256 private constant PRECISION = 1e18;

    function initialize(
        address _poolingManager,
        address _underlyingTokenAddress,
        address _yieldTokenAddress,
        uint256 yieldFactor
    ) public virtual initializer {
        initializeStrategyBase(_poolingManager, _underlyingTokenAddress, _yieldTokenAddress);
        _yieldFactor = yieldFactor;
    }

    function _deposit(uint256 amount) internal override {
        IERC20Extended _underlyingToken = IERC20Extended(underlyingToken);
        IERC20Extended _yieldToken = IERC20Extended(yieldToken);
        _underlyingToken.burn(address(this), amount);
        uint256 yieldAmount = _underlyingToYield(amount);
        _yieldToken.mint(address(this), yieldAmount);
    }

    function _withdraw(uint256 amount) internal override returns (uint256) {
        IERC20Extended _underlyingToken = IERC20Extended(underlyingToken);
        IERC20Extended _yieldToken = IERC20Extended(yieldToken);

        uint256 yieldAmount = _underlyingToYield(amount);
        _yieldToken.burn(address(this), yieldAmount);

        _underlyingToken.mint(address(this), amount);
        return amount;
    }

    function _yieldToUnderlying(uint256 amount) internal view override returns (uint256) {
        return (amount * PRECISION) / _yieldFactor;
    }

    function _underlyingToYield(uint256 amount) internal view override returns (uint256) {
        return (amount * _yieldFactor) / PRECISION;
    }
}
