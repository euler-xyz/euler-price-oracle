// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IOracle {
    function canQuote(uint256 inAmount, address base, address quote) external view returns (bool);
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256);
}
