// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/interfaces/IERC4626.sol";

interface IAaveUsdc is IERC4626 {
    function usdc() external view returns (address);
}
