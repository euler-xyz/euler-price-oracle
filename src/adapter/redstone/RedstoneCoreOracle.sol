// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {RedstoneDefaultsLib} from "@redstone/evm-connector/core/RedstoneDefaultsLib.sol";
import {PrimaryProdDataServiceConsumerBase} from
    "@redstone/evm-connector/data-services/PrimaryProdDataServiceConsumerBase.sol";
import {BaseAdapter, Errors} from "src/adapter/BaseAdapter.sol";
import {ScaleUtils, Scale} from "src/lib/ScaleUtils.sol";

/// @title RedstoneCoreOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for Redstone pull-based price feeds.
contract RedstoneCoreOracle is PrimaryProdDataServiceConsumerBase, BaseAdapter {
    /// @notice The address of the base asset corresponding to the feed.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the feed.
    address public immutable quote;
    /// @notice The identifier of the price feed.
    /// @dev See https://app.redstone.finance/#/app/data-services/redstone-primary-prod
    bytes32 public immutable feedId;
    /// @notice The decimals of the Redstone price feed.
    /// @dev Redstone price feeds have 8 decimals by default, however certain exceptions exist.
    uint8 public immutable feedDecimals;
    /// @notice The maximum allowed age of the price.
    uint256 public immutable maxStaleness;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy a RedstoneCoreOracle.
    /// @param _base The address of the base asset corresponding to the feed.
    /// @param _quote The address of the quote asset corresponding to the feed.
    /// @param _feedId The identifier of the price feed.
    /// @param _feedDecimals The decimals of the price feed.
    /// @param _maxStaleness The maximum allowed age of the price.
    /// @dev Base and quote are not required to correspond to the feed assets.
    /// Note: The chosen value for `maxStaleness` presents a tradeoff between liveness.
    /// Since singed price data is verified locally in `_getQuote`, callers are theoretically
    /// able to use any Redstone price between `now - maxStaleness` and `now`.
    /// On the other hand, `maxStaleness` effectively imposes a deadline on the transaction,
    /// so choosing an acceptance that is too short increases the change that the transaction is dropped,
    /// especially during chain congestion.
    constructor(address _base, address _quote, bytes32 _feedId, uint8 _feedDecimals, uint256 _maxStaleness) {
        base = _base;
        quote = _quote;
        feedId = _feedId;
        feedDecimals = _feedDecimals;
        maxStaleness = _maxStaleness;
        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, _feedDecimals);
    }

    /// @notice Validate the timestamp of a Redstone signed price data package.
    /// @param timestampMillis Data package timestamp in milliseconds.
    /// @dev This function will be called in `getOracleNumericValueFromTxMsg` in `getQuote`,
    /// overriding the accepted range to `[now - 1 minute, now + maxStaleness]`.
    /// Notably there are cases where the data timestamp is ahead of `block.timestamp`.
    /// This is an artifact of the Redstone system and we don't override this behavior.
    function validateTimestamp(uint256 timestampMillis) public view override {
        uint256 timestamp = timestampMillis / 1000;

        if (block.timestamp > timestamp && block.timestamp - timestamp > maxStaleness) {
            revert Errors.PriceOracle_InvalidAnswer();
        } else if (timestamp - block.timestamp > RedstoneDefaultsLib.DEFAULT_MAX_DATA_TIMESTAMP_AHEAD_SECONDS) {
            revert Errors.PriceOracle_InvalidAnswer();
        }
    }

    /// @notice Get the quote from the Redstone feed.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @dev Signed price data is appended to `msg.data`.
    /// The validation logic inherited from `PrimaryProdDataServiceConsumerBase`.
    /// @return The converted amount using the Redstone feed.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);
        uint256 price = getOracleNumericValueFromTxMsg(feedId);
        return ScaleUtils.calcOutAmount(inAmount, price, scale, inverse);
    }
}
