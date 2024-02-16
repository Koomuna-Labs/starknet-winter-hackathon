// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {StrategyBase} from "../StrategyBase.sol";
import {ErrorLib} from "../../lib/ErrorLib.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRETH} from "../../interfaces/IRETH.sol";
import {IRocketDepositPool} from "../../interfaces/IRocketDepositPool.sol";
import {IRocketStorage} from "../../interfaces/IRocketStorage.sol";

// goerli RocketDepositPool 0xa9A6A14A3643690D0286574976F45abBDAD8f505
// goerli RocketStorage 0xd8Cd47263414aFEca62d6e2a3917d6600abDceB3

contract RocketPoolStakingStrategy is StrategyBase {
     IRocketStorage public rocketStorage;
     IRocketDepositPool public rocketDepositPool;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize(
        address _poolingManager,
        address _underlyingToken,
        address _yieldToken,
        address _rocketStorageAddress
    ) public virtual initializer {
        // underlying token hardcoded? RP dice generar dinamicamente
        initializeStrategyBase(_poolingManager, _underlyingToken, _yieldToken);
        _initializeRocketPool(_rocketStorageAddress);
    }

    function _initializeRocketPool(address _rocketStorageAddress) internal {
        require(_rocketStorageAddress != address(0), "Zero address: RocketPool");
        rocketStorage = IRocketStorage(_rocketStorageAddress);
    }

    function _getRocketDepositPool() internal view returns (IRocketDepositPool) {
        address rocketDepositPoolAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketDepositPool")));
        return IRocketDepositPool(rocketDepositPoolAddress);
    }

    function _deposit(uint256 amount) internal override {
        rocketDepositPool = _getRocketDepositPool();
        rocketDepositPool.deposit{value: amount}();
    }

    function _withdraw(uint256 amount) internal override returns (uint256) {
         address rocketTokenRETHAddress = rocketStorage.getAddress(keccak256(abi.encodePacked("contract.address", "rocketTokenRETH")));
         IRETH rocketTokenRETH = IRETH(rocketTokenRETHAddress);
         require(rocketTokenRETH.transfer(address(this), amount), "rETH was not transferred to caller");
         return (amount);
    }

    
    function _underlyingToYield(uint256 amount) internal view override returns (uint256) {
        return IRETH(yieldToken).previewDeposit(amount);
    }

    function _yieldToUnderlying(uint256 amount) internal view override returns (uint256) {
        return IRETH(yieldToken).previewRedeem(amount);
    }
}
