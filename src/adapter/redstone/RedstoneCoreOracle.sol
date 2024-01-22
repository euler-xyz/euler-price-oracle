// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {PrimaryProdDataServiceConsumerBase} from
    "@redstone/evm-connector/data-services/PrimaryProdDataServiceConsumerBase.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for Redstone Core (pull-based)
contract RedstoneCoreOracle is PrimaryProdDataServiceConsumerBase {
    address public immutable base;
    address public immutable quote;
    bytes32 public immutable feedId;
    uint256 public immutable maxStaleness;
    bool public immutable inverse;
    uint8 internal immutable baseDecimals;
    uint8 internal immutable quoteDecimals;

    uint224 public lastPrice;
    uint32 public lastUpdatedAt;

    event PriceUpdated(uint256 indexed price);

    constructor(address _base, address _quote, bytes32 _feedId, uint256 _maxStaleness, bool _inverse) {
        base = _base;
        quote = _quote;
        feedId = _feedId;
        maxStaleness = _maxStaleness;
        inverse = _inverse;

        baseDecimals = ERC20(base).decimals();
        quoteDecimals = ERC20(quote).decimals();
    }

    function updatePrice() external {
        uint256 price = getOracleNumericValueFromTxMsg(feedId);
        if (price > type(uint224).max) revert Errors.EOracle_Overflow();
        lastPrice = uint224(price);
        lastUpdatedAt = uint32(block.timestamp);
        emit PriceUpdated(price);
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
        uint256 staleness = block.timestamp - lastUpdatedAt;
        if (staleness > maxStaleness) revert Errors.EOracle_TooStale(staleness, maxStaleness);

        if (inverse) return (inAmount * 10 ** quoteDecimals) / lastPrice;
        else return (inAmount * lastPrice) / 10 ** baseDecimals;
    }
}
