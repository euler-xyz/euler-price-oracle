// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IDIAOracleV2 {
    function getValue(string memory key) external view returns (uint128 value, uint128 timestamp);
}