// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IPyth} from "@pyth/IPyth.sol";
import {PythStructs} from "@pyth/PythStructs.sol";
import {BaseAdapter, Errors} from "src/adapter/BaseAdapter.sol";
import {ScaleUtils, Scale} from "src/lib/ScaleUtils.sol";

/// @title PythOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice PriceOracle adapter for Pyth pull-based price feeds.
/// @dev Integration Note: Pyth is a pull-based oracle which requires price updates to be pushed by the user.
/// Before calling `getQuote*` dispatch a call `updatePriceFeeds` on the Pyth oracle proxy to refresh the price.
/// This is best done atomically via a multicall contract such as the Ethereum Vault Connector (EVC).
contract PythOracle is BaseAdapter {
    /// @notice The maximum length of time that a price can be in the future.
    uint256 internal constant MAX_AHEADNESS = 1 minutes;
    /// @notice The maximum permitted value for `maxStaleness`.
    uint256 internal constant MAX_STALENESS_UPPER_BOUND = 15 minutes;
    /// @notice The minimum permitted value for `maxConfWidth`.
    /// @dev Equal to 0.1%.
    uint256 internal constant MAX_CONF_WIDTH_LOWER_BOUND = 10;
    /// @notice The maximum permitted value for `maxConfWidth`.
    /// @dev Equal to 5%.
    uint256 internal constant MAX_CONF_WIDTH_UPPER_BOUND = 500;
    /// @dev The smallest PythStruct exponent that the oracle can handle.
    int256 internal constant MIN_EXPONENT = -20;
    /// @dev The denominator for basis points values (maxConfWidth).
    uint256 internal constant BASIS_POINTS = 10_000;
    /// @notice The address of the Pyth oracle proxy.
    address public immutable pyth;
    /// @notice The address of the base asset corresponding to the feed.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the feed.
    address public immutable quote;
    /// @notice The id of the feed in the Pyth network.
    /// @dev See https://pyth.network/developers/price-feed-ids.
    bytes32 public immutable feedId;
    /// @notice The maximum allowed age of the price.
    uint256 public immutable maxStaleness;
    /// @notice The maximum allowed width of the confidence interval.
    /// @dev Note: this value is in basis points i.e. 500 = 5%.
    uint256 public immutable maxConfWidth;
    /// @dev Used for correcting for the decimals of base and quote.
    uint8 internal immutable baseDecimals;
    /// @dev Used for correcting for the decimals of base and quote.
    uint8 internal immutable quoteDecimals;

    /// @notice Deploy a PythOracle.
    /// @param _pyth The address of the Pyth oracle proxy.
    /// @param _base The address of the base asset corresponding to the feed.
    /// @param _quote The address of the quote asset corresponding to the feed.
    /// @param _feedId The id of the feed in the Pyth network.
    /// @param _maxStaleness The maximum allowed age of the price.
    /// @param _maxConfWidth The maximum width of the confidence interval in basis points.
    /// @dev Note: A high confidence interval indicates market volatility or Pyth consensus instability.
    /// Consider a lower `_maxConfWidth` for highly-correlated pairs and a higher value for uncorrelated pairs.
    /// Pairs with few data sources and low liquidity are more prone to volatility spikes and consensus instability.
    constructor(
        address _pyth,
        address _base,
        address _quote,
        bytes32 _feedId,
        uint256 _maxStaleness,
        uint256 _maxConfWidth
    ) {
        if (_maxStaleness > MAX_STALENESS_UPPER_BOUND) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }
        if (_maxConfWidth < MAX_CONF_WIDTH_LOWER_BOUND || _maxConfWidth > MAX_CONF_WIDTH_UPPER_BOUND) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        pyth = _pyth;
        base = _base;
        quote = _quote;
        feedId = _feedId;
        maxStaleness = _maxStaleness;
        maxConfWidth = _maxConfWidth;
        baseDecimals = _getDecimals(base);
        quoteDecimals = _getDecimals(quote);
    }

    /// @notice Fetch the latest Pyth price and transform it to a quote.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        PythStructs.Price memory priceStruct = _fetchPriceStruct();
        uint256 price = uint256(uint64(priceStruct.price));

        // priceStruct.expo will always be non-positive
        uint8 feedExponent = uint8(int8(baseDecimals) - int8(priceStruct.expo));
        Scale scale = ScaleUtils.from(quoteDecimals, feedExponent);
        return ScaleUtils.calcOutAmount(inAmount, price, scale, inverse);
    }

    /// @notice Get the latest Pyth price and perform sanity checks.
    /// @dev Revert conditions: update timestamp is too stale or too ahead, price is negative or zero,
    /// confidence interval is too wide, exponent is positive or too small.
    /// @return The Pyth price struct without modification.
    function _fetchPriceStruct() internal view returns (PythStructs.Price memory) {
        PythStructs.Price memory p = IPyth(pyth).getPriceUnsafe(feedId);
        if (p.publishTime < block.timestamp) {
            uint256 staleness = block.timestamp - p.publishTime;
            if (staleness > maxStaleness) revert Errors.PriceOracle_InvalidAnswer();
        } else {
            uint256 aheadness = p.publishTime - block.timestamp;
            if (aheadness > MAX_AHEADNESS) revert Errors.PriceOracle_InvalidAnswer();
        }

        if (
            p.price <= 0 || p.conf > uint64(p.price) * maxConfWidth / BASIS_POINTS || p.expo > 0
                || p.expo < MIN_EXPONENT
        ) {
            revert Errors.PriceOracle_InvalidAnswer();
        }
        return p;
    }
}
