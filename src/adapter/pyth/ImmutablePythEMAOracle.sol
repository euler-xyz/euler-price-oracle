// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pyth-sdk-solidity/PythStructs.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";

contract ImmutablePythEMAOracle is PythOracle {
    constructor(address _pyth, uint256 _maxStaleness, address[] memory tokens, bytes32[] memory feedIds)
        PythOracle(_pyth, _maxStaleness, tokens, feedIds)
    {}

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        PythStructs.Price memory baseStruct = _fetchEMAPriceStruct(base);
        PythStructs.Price memory quoteStruct = _fetchEMAPriceStruct(quote);

        uint8 baseDecimals = configs[base].decimals;
        uint8 quoteDecimals = configs[quote].decimals;

        return _combinePrices(inAmount, baseStruct, quoteStruct, baseDecimals, quoteDecimals);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        PythStructs.Price memory baseStruct = _fetchEMAPriceStruct(base);
        PythStructs.Price memory quoteStruct = _fetchEMAPriceStruct(quote);

        uint8 baseDecimals = configs[base].decimals;
        uint8 quoteDecimals = configs[quote].decimals;

        return _combinePricesWithSpread(inAmount, baseStruct, quoteStruct, baseDecimals, quoteDecimals);
    }
}
