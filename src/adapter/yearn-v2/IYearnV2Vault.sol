// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IYearnV2Vault {
    function pricePerShare() external view returns (uint256);
    function token() external view returns (address);
}
