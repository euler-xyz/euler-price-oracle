// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface ICurveStableSwapNGPool {
    function D_oracle() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function coins(uint256 i) external view returns (address);
}
