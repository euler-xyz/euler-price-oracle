// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "@solady/tokens/ERC20.sol";

contract MockERC20 is ERC20 {
    string private $name;
    string private $symbol;
    uint8 private $decimals;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        $name = name_;
        $symbol = symbol_;
        $decimals = decimals_;
    }

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        _burn(account, amount);
    }

    function name() public view virtual override returns (string memory) {
        return $name;
    }

    function symbol() public view virtual override returns (string memory) {
        return $symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return $decimals;
    }
}
