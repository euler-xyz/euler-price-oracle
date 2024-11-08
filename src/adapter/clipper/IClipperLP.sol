// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IClipperLP {
    function allTokensBalance() external view returns (uint256[] memory, address[] memory, uint256);
    function isTradeHalted() external view returns (bool);
}
