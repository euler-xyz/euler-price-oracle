// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {PrimaryProdDataServiceConsumerBase} from
    "@redstone/evm-connector/data-services/PrimaryProdDataServiceConsumerBase.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author totomanov
/// @notice Adapter for Redstone Core (pull-based)
contract RedstoneCoreOracle is PrimaryProdDataServiceConsumerBase {
    address public immutable base;
    address public immutable quote;
    bytes32 public immutable feedId;
    uint256 public immutable maxStaleness;
    bool public immutable inverse;
    uint8 internal immutable baseDecimals;
    uint8 internal immutable quoteDecimals;

    constructor(address _base, address _quote, bytes32 _feedId, uint32 _maxStaleness, bool _inverse) {
        base = _base;
        quote = _quote;
        feedId = _feedId;
        maxStaleness = _maxStaleness;
        inverse = _inverse;

        baseDecimals = ERC20(base).decimals();
        quoteDecimals = ERC20(quote).decimals();
    }

    function getQuote(uint256 inAmount, address _base, address _quote) external view returns (uint256) {
        return _getQuote(inAmount, _base, _quote);
    }

    function getQuotes(uint256 inAmount, address _base, address _quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, _base, _quote);
        return (outAmount, outAmount);
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.RedstoneCoreOracle(maxStaleness);
    }

    function _getQuote(uint256 inAmount, address _base, address _quote) internal view returns (uint256) {
        if (_base != base || _quote != quote) revert Errors.EOracle_NotSupported(_base, _quote);
        uint256 unitPrice = getOracleNumericValueFromTxMsg(feedId);
        if (inverse) return (inAmount * 10 ** quoteDecimals) / unitPrice;
        else return (inAmount * unitPrice) / 10 ** baseDecimals;
    }
}
