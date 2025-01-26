// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface ICurvePool {
    function coins(uint256 i) external view returns (address);
    function price_oracle(uint256 i) external view returns (uint256);
    function price_oracle() external view returns (uint256);
    function lpPrice() external view returns (uint256);
}
