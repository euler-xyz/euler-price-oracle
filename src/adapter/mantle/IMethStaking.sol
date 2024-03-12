// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IMethStaking {
    function ethToMETH(uint256 ethAmount) external view returns (uint256);
    function mETHToETH(uint256 mETHAmount) external view returns (uint256);
}
