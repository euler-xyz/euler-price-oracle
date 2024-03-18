// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IChronicle {
    function readWithAge() external view returns (uint256 value, uint256 age);
    function decimals() external view returns (uint8);
}
