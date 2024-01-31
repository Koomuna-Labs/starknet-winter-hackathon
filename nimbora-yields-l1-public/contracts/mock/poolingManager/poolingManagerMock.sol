// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import "../../interfaces/IStrategyBase.sol";

interface IPoolingManagerMock {
    function handleReport(address strategy, uint256 actionId, uint256 amount) external;

    function hasRole(bytes32 role, address account) external view returns (bool);
}

contract PoolingManagerMock is IPoolingManagerMock {
    uint256 public lastNav;
    uint256 public lastWithdrawalAmount;
    address public owner;

    constructor() {
        owner = address(msg.sender);
    }

    function handleReport(address strategy, uint256 actionId, uint256 amount) external {
        (lastNav, lastWithdrawalAmount) = IStrategyBase(strategy).handleReport(actionId, amount);
    }

    function hasRole(bytes32 role, address account) external view returns (bool) {
        if (owner == address(account)) {
            return (true);
        } else {
            return (false);
        }
    }
}
