// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IStarknetBridge {
    function deposit(uint256 amount, uint256 l2Recipient) external payable;

    function withdraw(uint256 amount, address recipient) external;

    function depositCancelRequest(uint256 amount, uint256 l2Recipient, uint256 nonce) external;

    function depositReclaim(uint256 amount, uint256 l2Recipient, uint256 nonce) external;
}
