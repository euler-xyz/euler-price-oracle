// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IWBETH {
    function exchangeRate() external view returns (uint256);
}
