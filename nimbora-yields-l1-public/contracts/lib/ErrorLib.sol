// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.20;

library ErrorLib {
    error NotRelayer();
    error UnknownUnderlying();
    error ZeroAddress();
    error InvalidEthAmount();
    error InvalidCaller();
    error UnknownActionId();
    error InvalidSlippage();
    error InvalidDecimals();
    error InvalidPoolingManager();
    error NoL1Report();
    error NotEnoughSuccessCalls();
}
