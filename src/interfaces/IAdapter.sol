// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IAdapter {
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 out);
}
