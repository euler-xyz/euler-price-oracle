// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

interface IOracle {
    // function canQuote(uint256 inAmount, address base, address quote) external view returns (bool);
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256);
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        returns (uint256 bidOut, uint256 askOut);
}
