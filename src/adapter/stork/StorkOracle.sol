// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../lib/ScaleUtils.sol";
import "./IStork.sol";
import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {IStorkTemporalNumericValueUnsafeGetter} from "./IStork.sol";

/// @title StorkOracle
/// @custom:security-contact security@euler.xyz
/// @author Stork Labs (https://www.stork.network/)
/// @notice PriceOracle adapter for Stork price feeds.
contract StorkOracle is BaseAdapter {
    /// @notice The maximum length of time that a price can be in the future.
    uint256 internal constant MAX_AHEADNESS = 1 minutes;
    /// @notice The maximum permitted value for `maxStaleness`.
    uint256 internal constant MAX_STALENESS_UPPER_BOUND = 15 minutes;
    // @notice The number of decimals in values returned by the Stork contract.
    int8 internal constant STORK_DECIMALS = 18;
    /// @inheritdoc IPriceOracle
    string public constant name = "StorkOracle";
    /// @notice The address of the Stork oracle proxy.
    address public immutable stork;
    /// @notice The address of the base asset corresponding to the feed.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the feed.
    address public immutable quote;
    /// @notice The id of the feed in the Stork network.
    /// @dev See https://docs.stork.network/resources/asset-id-registry.
    bytes32 public immutable feedId;
    /// @notice The maximum allowed age of the price.
    uint256 public immutable maxStaleness;
    /// @dev Used for correcting for the decimals of base and quote.
    uint8 internal immutable baseDecimals;
    /// @dev Used for correcting for the decimals of base and quote.
    uint8 internal immutable quoteDecimals;

    /// @notice Deploy a StorkOracle.
    /// @param _stork The address of the Stork oracle proxy.
    /// @param _base The address of the base asset corresponding to the feed.
    /// @param _quote The address of the quote asset corresponding to the feed.
    /// @param _feedId The id of the feed in the Stork network.
    /// @param _maxStaleness The maximum allowed age of the price.
    constructor(
        address _stork,
        address _base,
        address _quote,
        bytes32 _feedId,
        uint256 _maxStaleness
    ) {
        if (_maxStaleness > MAX_STALENESS_UPPER_BOUND) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        stork = _stork;
        base = _base;
        quote = _quote;
        feedId = _feedId;
        maxStaleness = _maxStaleness;
        baseDecimals = _getDecimals(base);
        quoteDecimals = _getDecimals(quote);
    }

    /// @notice Fetch the latest Stork price and transform it to a quote.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        StorkStructs.TemporalNumericValue memory temporalNumericValue = _fetchTemporalNumericValue();

        uint256 value = uint256(uint192(temporalNumericValue.quantizedValue));
        int8 feedExponent = int8(baseDecimals) + STORK_DECIMALS;

        Scale scale;
        if (feedExponent > 0) {
            scale = ScaleUtils.from(quoteDecimals, uint8(feedExponent));
        } else {
            scale = ScaleUtils.from(quoteDecimals + uint8(-feedExponent), 0);
        }
        return ScaleUtils.calcOutAmount(inAmount, value, scale, inverse);
    }

    /// @notice Get the latest Stork price and perform sanity checks.
    /// @dev Revert conditions: update timestamp is too stale or too ahead, price is negative or zero,
    /// @return The Stork price struct without modification.
    function _fetchTemporalNumericValue() internal view returns (StorkStructs.TemporalNumericValue memory) {
        StorkStructs.TemporalNumericValue memory v = IStorkTemporalNumericValueUnsafeGetter(stork).getTemporalNumericValueUnsafeV1(feedId);
        uint256 publishTimestampSeconds = v.timestampNs / 1e9;
        if (publishTimestampSeconds < block.timestamp) {
            // Verify that the price is not too stale
            uint256 staleness = block.timestamp - publishTimestampSeconds;
            if (staleness > maxStaleness) revert Errors.PriceOracle_InvalidAnswer();
        } else {
            // Verify that the price is not too ahead
            uint256 aheadness = publishTimestampSeconds - block.timestamp;
            if (aheadness > MAX_AHEADNESS) revert Errors.PriceOracle_InvalidAnswer();
        }

        if (v.quantizedValue <= 0) {
            revert Errors.PriceOracle_InvalidAnswer();
        }
        return v;
    }
}