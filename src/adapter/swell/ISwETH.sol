// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface ISwETH {
    function ethToSwETHRate() external view returns (uint256);
    function swETHToETHRate() external view returns (uint256);
}
