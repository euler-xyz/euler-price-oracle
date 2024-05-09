// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {RedstoneDefaultsLib} from "@redstone/evm-connector/core/RedstoneDefaultsLib.sol";
import {PrimaryProdDataServiceConsumerBase} from
    "@redstone/evm-connector/data-services/PrimaryProdDataServiceConsumerBase.sol";
import {BaseAdapter, Errors, IPriceOracle} from "src/adapter/BaseAdapter.sol";
import {ScaleUtils, Scale} from "src/lib/ScaleUtils.sol";

/// @title RedstoneCoreOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for Redstone pull-based price feeds.
contract RedstoneCoreOracle is PrimaryProdDataServiceConsumerBase, BaseAdapter {
    /// @notice Struct holding information about the latest price.
    struct Cache {
        /// @notice The Redstone price.
        uint160 price;
        /// @notice The timestamp contained within the price data packages.
        uint48 priceTimestamp;
        /// @notice A transient value to enforce consistent timestamps in data packages.
        uint48 tempTimestamp;
    }

    /// @notice The maximum permitted value for `maxStaleness`.
    uint256 internal constant MAX_STALENESS_UPPER_BOUND = 5 minutes;
    /// @notice The initial value for the `cache.tempTimestamp`.
    uint48 internal constant TEMP_TIMESTAMP_INITIAL = type(uint48).max;
    /// @inheritdoc IPriceOracle
    string public constant name = "RedstoneCoreOracle";
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
    /// @notice The maximum allowed age of the Redstone price.
    /// @dev Compares `block.timestamp` against the timestamp of the Redstone data package.
    uint256 public immutable maxStaleness;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;
    /// @notice The last updated Redstone price and its timestamp.
    /// @dev The cache is updated in `updatePrice`.
    Cache public cache;

    /// @notice The cache timestamp was updated.
    /// @param price The Redstone price.
    /// @param priceTimestamp The timestamp contained within the price data packages.
    event CacheUpdated(uint256 price, uint256 priceTimestamp);

    /// @notice Deploy a RedstoneCoreOracle.
    /// @param _base The address of the base asset corresponding to the feed.
    /// @param _quote The address of the quote asset corresponding to the feed.
    /// @param _feedId The identifier of the price feed.
    /// @param _feedDecimals The decimals of the price feed.
    /// @param _maxStaleness The maximum allowed age of the Redstone price in `updatePrice`.
    /// @dev Since Redstone prices are verified locally, callers can pass data up to `maxStaleness` seconds old.
    /// If `maxStaleness` is too short, the update transaction may revert.
    constructor(address _base, address _quote, bytes32 _feedId, uint8 _feedDecimals, uint256 _maxStaleness) {
        if (_maxStaleness > MAX_STALENESS_UPPER_BOUND) revert Errors.PriceOracle_InvalidConfiguration();

        base = _base;
        quote = _quote;
        feedId = _feedId;
        feedDecimals = _feedDecimals;
        maxStaleness = _maxStaleness;
        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, _feedDecimals);
        cache = Cache({price: 0, priceTimestamp: 0, tempTimestamp: TEMP_TIMESTAMP_INITIAL});
    }

    /// @notice Ingest a signed update message and cache it on the contract.
    /// @dev Validation logic inherited from `PrimaryProdDataServiceConsumerBase`.
    /// The price timestamp must lie in the defined acceptance range relative to `block.timestamp`.
    /// Note: The Redstone SDK allows the price timestamp to be up to 1 minute in the future.
    function updatePrice() external {
        // The internal call chain also dispatches calls to `validateTimestamp`.
        uint256 price = getOracleNumericValueFromTxMsg(feedId);
        if (price == 0) revert Errors.PriceOracle_InvalidAnswer();
        if (price > type(uint160).max) revert Errors.PriceOracle_Overflow();

        Cache memory _cache = cache;
        // `tempTimestamp` currently holds the timestamp of the ingested Redstone payload.
        uint256 timestamp = _cache.tempTimestamp;
        if (timestamp == _cache.priceTimestamp) {
            // The price was already updated at this timestamp. Reset `tempTimestamp` and return early.
            cache.tempTimestamp = TEMP_TIMESTAMP_INITIAL;
            return;
        }
        // Price updates must have a more recent timestamp.
        if (timestamp < _cache.priceTimestamp) revert Errors.PriceOracle_InvalidAnswer();

        if (block.timestamp > timestamp) {
            // Verify that the timestamp is not too stale.
            uint256 staleness = block.timestamp - timestamp;
            if (staleness > maxStaleness) {
                revert Errors.PriceOracle_TooStale(staleness, maxStaleness);
            }
        } else if (timestamp - block.timestamp > RedstoneDefaultsLib.DEFAULT_MAX_DATA_TIMESTAMP_AHEAD_SECONDS) {
            // Verify that the timestamp is not too long in the future (1 min). Redstone SDK explicitly allows this.
            revert Errors.PriceOracle_InvalidAnswer();
        }

        // Store the price and timestamp in the cache. Reset the temp timestamp to the magic value.
        cache = Cache({price: uint160(price), priceTimestamp: uint48(timestamp), tempTimestamp: TEMP_TIMESTAMP_INITIAL});
        emit CacheUpdated(price, timestamp);
    }

    /// @notice Validate the timestamp of a Redstone signed price data package.
    /// @param timestampMillis Data package timestamp in milliseconds.
    /// @dev Internally called in `updatePrice` for every signed data package in the payload.
    /// Note: Although this function is `view`, it may in fact perform state updates when called via `updatePrice`.
    /// External calls will revert due to the `msg.sig` guard. Visibility is kept `public` to override the SDK.
    function validateTimestamp(uint256 timestampMillis) public view virtual override {
        // Block external calls to `validateTimestamp`.
        if (msg.sig != RedstoneCoreOracle.updatePrice.selector) revert Errors.PriceOracle_InvalidAnswer();
        // Cast the state mutability of `validateTimestamp` to `view`.
        // Updating storage in an internal call to a function marked as `view` does not result in a runtime error.
        // This is because internal calls are entered with a `JUMP` instruction rather than `STATICCALL`.
        asView(_validateTimestamp)(timestampMillis);
    }

    /// @notice Enforce that all data packages in the `updatePrice` payload have the same timestamp.
    /// @param timestampMillis Data package timestamp in milliseconds.
    function _validateTimestamp(uint256 timestampMillis) internal {
        uint256 timestamp = timestampMillis / 1000;
        // This function is called for each signer in the `updatePrice` payload.
        // We store the first timestamp in `cache.tempTimestamp` and compare the rest against it.
        uint256 tempTimestamp = cache.tempTimestamp;
        if (tempTimestamp == TEMP_TIMESTAMP_INITIAL) {
            // We store the first data package's timestamp temporarily compare it against subsequent timestamps.
            cache.tempTimestamp = uint48(timestamp);
        } else if (tempTimestamp != timestamp) {
            // Verify that all subsequent data packages in the payload have the same timestamp as the first one.
            revert Errors.PriceOracle_InvalidAnswer();
        }
    }

    /// @notice Get the quote from the Redstone feed.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the Redstone feed.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        Cache memory _cache = cache;
        if (block.timestamp > _cache.priceTimestamp) {
            // No need to check price timestamps in the future as they can only get more recent with time.
            uint256 priceStaleness = block.timestamp - _cache.priceTimestamp;
            if (priceStaleness > maxStaleness) {
                revert Errors.PriceOracle_TooStale(priceStaleness, maxStaleness);
            }
        }
        return ScaleUtils.calcOutAmount(inAmount, _cache.price, scale, inverse);
    }

    /// @notice Cast the state mutability of a function pointer from `nonpayable` to `view`.
    /// @dev Credit to [0age](https://twitter.com/z0age/status/1654922202930888704) for this trick.
    /// @param fn A pointer to a function with `nonpayable` (default) state mutability.
    /// @return fnAsView A pointer to the same function with its state mutability cast to `view`.
    function asView(function(uint256) internal fn) internal pure returns (function(uint256) internal view fnAsView) {
        assembly {
            fnAsView := fn
        }
    }
}
