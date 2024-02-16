// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {StrategyBase} from "../StrategyBase.sol";
import {ErrorLib} from "../../lib/ErrorLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAaveUsdc} from "../../interfaces/IAaveUsdc.sol";

contract AaveUsdcStrategy is StrategyBase {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _poolingManager,
        address _underlyingToken,
        address _yieldToken
    ) public virtual initializer {
        initializeStrategyBase(_poolingManager, _underlyingToken, _yieldToken);
        _checkAndInitAaveUsdc(_underlyingToken, _yieldToken);
    }

    function _checkAndInitAaveUsdc(address _underlyingToken, address _yieldToken) internal {
        address usdc = IAaveUsdc(_yieldToken).usdc();
        require(usdc == _underlyingToken, "Invalid underlying: Aave Strategy");
        IERC20(_underlyingToken).approve(_yieldToken, type(uint256).max);
    }

    function _deposit(uint256 amount) internal override {
        IAaveUsdc(yieldToken).deposit(amount, address(this));
    }

    function _withdraw(uint256 amount) internal override returns (uint256) {
        uint256 yieldAmountToDeposit = IAaveUsdc(yieldToken).previewWithdraw(amount);
        uint256 yieldBalance = yieldBalance();
        if (yieldAmountToDeposit > yieldBalance) {
            uint256 assets = IAaveUsdc(yieldToken).redeem(yieldBalance, poolingManager, address(this));
            return (assets);
        } else {
            uint256 assets = IAaveUsdc(yieldToken).withdraw(amount, poolingManager, address(this));
            return (amount);
        }
    }

    function _underlyingToYield(uint256 amount) internal view override returns (uint256) {
        return IAaveUsdc(yieldToken).previewDeposit(amount);
    }

    function _yieldToUnderlying(uint256 amount) internal view override returns (uint256) {
        return IAaveUsdc(yieldToken).previewRedeem(amount);
    }
}
