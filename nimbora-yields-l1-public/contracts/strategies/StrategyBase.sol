// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IStrategyBase.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import "../lib/ErrorLib.sol";

abstract contract StrategyBase is Initializable, PausableUpgradeable, IStrategyBase {
    address public poolingManager;
    address public underlyingToken;
    address public yieldToken;

    function initializeStrategyBase(
        address _l2PoolingManager,
        address _underlyingToken,
        address _yieldToken
    ) public initializer {
        __Pausable_init();
        if (_l2PoolingManager == address(0)) revert ErrorLib.ZeroAddress();
        if (_underlyingToken == address(0)) revert ErrorLib.ZeroAddress();
        if (_yieldToken == address(0)) revert ErrorLib.ZeroAddress();
        poolingManager = _l2PoolingManager;
        underlyingToken = _underlyingToken;
        yieldToken = _yieldToken;
    }

    function handleReport(
        uint256 actionId,
        uint256 amount
    ) external payable override whenNotPaused returns (uint256, uint256) {
        _assertOnlyPoolingManager();
        uint256 withdrawalAmount = 0;
        if (actionId == DEPOSIT) {
            _deposit(amount);
        } else if (actionId == WITHDRAW) {
            withdrawalAmount = _withdraw(amount);
            // Transfer to pooling manager should be implemented in _withdraw()
        } else if (actionId == REPORT) {} else {
            revert ErrorLib.UnknownActionId();
        }
        return (_nav(), withdrawalAmount);
    }

    function nav() public view returns (uint256) {
        return _nav();
    }

    function yieldToUnderlying(uint256 amount) public view returns (uint256) {
        return _yieldToUnderlying(amount);
    }

    function underlyingToYield(uint256 amount) public view returns (uint256) {
        return _underlyingToYield(amount);
    }

    function yieldBalance() public view returns (uint256) {
        return IERC20(yieldToken).balanceOf(address(this));
    }

    function _assertOnlyPoolingManager() internal view {
        if (address(msg.sender) != poolingManager) revert ErrorLib.InvalidCaller();
    }

    function _assertOnlyRoleOwner() internal view {
        if (!IAccessControl(poolingManager).hasRole(0, address(msg.sender))) revert ErrorLib.InvalidCaller();
    }

    function _deposit(uint256 amount) internal virtual;

    function _withdraw(uint256 amount) internal virtual returns (uint256);

    function _nav() internal view returns (uint256) {
        return _yieldToUnderlying(yieldBalance());
    }

    function _yieldToUnderlying(uint256 amount) internal view virtual returns (uint256);

    function _underlyingToYield(uint256 amount) internal view virtual returns (uint256);
}
