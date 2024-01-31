// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.20;

contract StarknetEthBridgeMock {
    function deposit(uint256 amount, uint256 l2Recipient) external payable {}

    function withdraw(uint256 amount, address recipient) external {
        payable(recipient).transfer(amount);
    }

    receive() external payable {}
}
