// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pyth-sdk-solidity/PythStructs.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {BasePythOracle} from "src/adapter/pyth/BasePythOracle.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract PythEMAOracle is BasePythOracle {
    constructor(address _pyth, uint256 _maxStaleness) BasePythOracle(_pyth, _maxStaleness) {}

    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        PythStructs.Price memory baseStruct = _fetchEMAPriceStruct(base);
        PythStructs.Price memory quoteStruct = _fetchEMAPriceStruct(quote);

        uint8 baseDecimals = configs[base].decimals;
        uint8 quoteDecimals = configs[quote].decimals;

        return _combinePrices(inAmount, baseStruct, quoteStruct, baseDecimals, quoteDecimals);
    }

    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        PythStructs.Price memory baseStruct = _fetchEMAPriceStruct(base);
        PythStructs.Price memory quoteStruct = _fetchEMAPriceStruct(quote);

        uint8 baseDecimals = configs[base].decimals;
        uint8 quoteDecimals = configs[quote].decimals;

        return _combinePricesWithSpread(inAmount, baseStruct, quoteStruct, baseDecimals, quoteDecimals);
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.PythEMAOracle(maxStaleness);
    }
}
