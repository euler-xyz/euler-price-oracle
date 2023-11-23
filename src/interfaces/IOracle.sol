// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {OracleDescription} from "src/lib/OracleDescription.sol";

interface IOracle {
    function description() external view returns (OracleDescription.Description memory);
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256);
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        returns (uint256 bidOut, uint256 askOut);
}
