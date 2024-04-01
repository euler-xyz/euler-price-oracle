// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

interface IPot {
    function chi() external view returns (uint256);
    function rho() external view returns (uint256);
    function dsr() external view returns (uint256);
}
