// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StarkneErc20BridgeMock {
    IERC20 public underlying;

    constructor(IERC20 _underlying) {
        underlying = _underlying;
    }

    function deposit(uint256 _amount, uint256) external payable {
        underlying.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 amount, address recipient) external {
        underlying.transfer(recipient, amount);
    }

    receive() external payable {}
}
