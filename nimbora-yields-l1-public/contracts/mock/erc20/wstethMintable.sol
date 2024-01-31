// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WstethMintable is ERC20 {
    uint256 public stEthPerTokenValue;

    constructor(uint256 _stEthPerTokenValue) ERC20("WstethMock", "wsteth") {
        stEthPerTokenValue = _stEthPerTokenValue;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external {
        _burn(account, amount);
    }

    function stEthPerToken() external view returns (uint256) {
        return stEthPerTokenValue;
    }
}
