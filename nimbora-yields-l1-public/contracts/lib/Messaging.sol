// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IStarknetMessaging} from "../interfaces/IStarknetMessaging.sol";
import {IStarknetBridge} from "../interfaces/IStarknetBridge.sol";

/// @title Messaging contract.
/// @author Spaceshard team 2023.
contract Messaging {
    uint256 private constant UINT256_PART_SIZE_BITS = 128;
    uint256 private constant UINT256_PART_SIZE = 2 ** UINT256_PART_SIZE_BITS;

    /// @notice Starknet messaging interface.
    IStarknetMessaging public starknetCore;

    /// @notice initialize the trove handler.
    /// @param _starknetCore Starknet core interface.
    function initializeMessaging(address _starknetCore) internal {
        starknetCore = IStarknetMessaging(_starknetCore);
    }

    /// @notice Consume l2 message.
    function _consumeL2Message(uint256 l2ContractAddress, uint256[] memory data) internal {
        starknetCore.consumeMessageFromL2(l2ContractAddress, data);
    }

    /// @notice Withdraw tokens from Starkgate bridge.
    function _withdrawTokenFromBridge(address l1BridgeAddress, address _receiver, uint256 _amount) internal {
        IStarknetBridge(l1BridgeAddress).withdraw(_amount, _receiver);
    }

    /// @notice deposit tokens to Starknet bridge.
    function depositToBridgeToken(
        address l1BridgeAddress,
        uint256 _l2Receiver,
        uint256 _amount,
        uint256 _value
    ) internal {
        if (_amount > 0) {
            IStarknetBridge(l1BridgeAddress).deposit{value: _value}(_amount, _l2Receiver);
        }
    }

    /// @notice cancel deposit tokens to Starknet bridge.
    function depositCancelRequestToBridgeToken(
        address l1BridgeAddress,
        uint256 _l2Receiver,
        uint256 _amount,
        uint256 _nonce
    ) internal {
        if (_amount > 0) {
            IStarknetBridge(l1BridgeAddress).depositCancelRequest(_amount, _l2Receiver, _nonce);
        }
    }

    /// @notice cancel deposit tokens to Starknet bridge.
    function depositReclaimToBridgeToken(
        address l1BridgeAddress,
        uint256 _l2Receiver,
        uint256 _amount,
        uint256 _nonce
    ) internal {
        if (_amount > 0) {
            IStarknetBridge(l1BridgeAddress).depositReclaim(_amount, _l2Receiver, _nonce);
        }
    }

    /// @notice send message to l2.
    function _sendMessageToL2(
        uint256 _l2Contract,
        uint256 _selector,
        uint256[] memory payload,
        uint256 _value
    ) internal {
        starknetCore.sendMessageToL2{value: _value}(_l2Contract, _selector, payload);
    }

    function u256(uint256 _value) internal pure returns (uint256 low, uint256 high) {
        low = _value & (UINT256_PART_SIZE - 1);
        high = _value >> UINT256_PART_SIZE_BITS;
    }
}
