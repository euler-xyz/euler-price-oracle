// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pyth-sdk-solidity/PythStructs.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract ImmutablePythOracle is PythOracle {
    constructor(address _pyth, uint256 _maxStaleness, ConfigParams[] memory _initialConfigs)
        PythOracle(_pyth, _maxStaleness, _initialConfigs)
    {}

    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        PythStructs.Price memory baseStruct = _fetchPriceStruct(base);
        PythStructs.Price memory quoteStruct = _fetchPriceStruct(quote);

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
        PythStructs.Price memory baseStruct = _fetchPriceStruct(base);
        PythStructs.Price memory quoteStruct = _fetchPriceStruct(quote);

        uint8 baseDecimals = configs[base].decimals;
        uint8 quoteDecimals = configs[quote].decimals;

        return _combinePricesWithSpread(inAmount, baseStruct, quoteStruct, baseDecimals, quoteDecimals);
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.ImmutablePythOracle(maxStaleness);
    }
}
