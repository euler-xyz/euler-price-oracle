// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseAdapter, Errors, IPriceOracle} from "src/adapter/BaseAdapter.sol";
import {IDapiProxy} from "src/adapter/api3/IDapiProxy.sol";
import {ScaleUtils, Scale} from "src/lib/ScaleUtils.sol";

/// @title API3Oracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice PriceOracle adapter for API3 push-based price feeds.
/// @dev Integration Note: `maxStaleness` is an immutable parameter set in the constructor.
/// If the aggregator's heartbeat changes, this adapter may exhibit unintended behavior.
contract API3Oracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "API3Oracle";
    /// @notice The minimum permitted value for `maxStaleness`.
    uint256 internal constant MAX_STALENESS_LOWER_BOUND = 1 minutes;
    /// @notice The maximum permitted value for `maxStaleness`.
    uint256 internal constant MAX_STALENESS_UPPER_BOUND = 72 hours;
    /// @notice The decimals of the API3 price feed. Fixed to 18.
    uint8 internal constant FEED_DECIMALS = 18;
    /// @notice The address of the base asset corresponding to the feed.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the feed.
    address public immutable quote;
    /// @notice The address of the API3 price feed.
    /// @dev https://market.api3.org/
    address public immutable feed;
    /// @notice The maximum allowed age of the price.
    /// @dev Reverts if block.timestamp - updatedAt > maxStaleness.
    uint256 public immutable maxStaleness;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy an API3Oracle.
    /// @param _base The address of the base asset corresponding to the feed.
    /// @param _quote The address of the quote asset corresponding to the feed.
    /// @param _feed The address of the API3 price feed.
    /// @param _maxStaleness The maximum allowed age of the price.
    /// @dev Consider setting `_maxStaleness` to slightly more than the feed's heartbeat
    /// to account for possible network delays when the heartbeat is triggered.
    constructor(address _base, address _quote, address _feed, uint256 _maxStaleness) {
        if (_maxStaleness < MAX_STALENESS_LOWER_BOUND || _maxStaleness > MAX_STALENESS_UPPER_BOUND) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        base = _base;
        quote = _quote;
        feed = _feed;
        maxStaleness = _maxStaleness;

        // The scale factor is used to correctly convert decimals.
        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, FEED_DECIMALS);
    }

    /// @notice Get the quote from the API3 feed.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the API3 feed.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        (int224 answer, uint32 updatedAt) = IDapiProxy(feed).read();
        if (answer <= 0) revert Errors.PriceOracle_InvalidAnswer();
        uint256 staleness = block.timestamp - updatedAt;
        if (staleness > maxStaleness) revert Errors.PriceOracle_TooStale(staleness, maxStaleness);

        uint256 price = uint256(uint224(answer));
        return ScaleUtils.calcOutAmount(inAmount, price, scale, inverse);
    }
}
