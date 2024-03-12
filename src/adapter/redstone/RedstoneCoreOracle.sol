// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {PrimaryProdDataServiceConsumerBase} from
    "@redstone/evm-connector/data-services/PrimaryProdDataServiceConsumerBase.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {BaseAdapter} from "src/adapter/BaseAdapter.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title RedstoneCoreOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for Redstone pull-based price feeds.
/// @dev To use the oracle, fetch the update data off-chain,
/// call `updatePrice` to update `lastPrice` and then call `getQuote`.
contract RedstoneCoreOracle is PrimaryProdDataServiceConsumerBase, BaseAdapter {
    /// @notice The address of the base asset corresponding to the feed.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the feed.
    address public immutable quote;
    /// @notice The identifier of the price feed.
    /// @dev See https://pyth.network/developers/price-feed-ids.
    bytes32 public immutable feedId;
    /// @notice The maximum allowed age of the price.
    uint256 public immutable maxStaleness;
    /// @notice Whether the feed returns the price of base/quote or quote/base.
    bool public immutable inverse;
    /// @dev The scale factor used to convert decimals.
    uint256 internal immutable scaleFactor;
    /// @notice The last updated price.
    /// @dev This gets updated after calling `updatePrice`.
    uint224 public lastPrice;
    /// @notice The timestamp of the last update.
    /// @dev Gets updated ot `block.timestamp` after calling `updatePrice`.
    uint32 public lastUpdatedAt;

    /// @notice Deploy a RedstoneCoreOracle.
    /// @param _base The address of the base asset corresponding to the feed.
    /// @param _quote The address of the quote asset corresponding to the feed.
    /// @param _feedId The identifier of the price feed.
    /// @param _maxStaleness The maximum allowed age of the price.
    /// @param _inverse Whether the feed returns the price of base/quote or quote/base.
    /// @dev Base and quote are not required to correspond to the feed assets.
    /// For example, the ETH/USD feed can be used to price WETH/USDC.
    constructor(address _base, address _quote, bytes32 _feedId, uint256 _maxStaleness, bool _inverse) {
        base = _base;
        quote = _quote;
        feedId = _feedId;
        maxStaleness = _maxStaleness;
        inverse = _inverse;

        uint8 decimals = ERC20(inverse ? _quote : _base).decimals();
        scaleFactor = 10 ** decimals;
    }

    /// @notice Ingest a signed update message and cache it on the contract.
    /// @dev Validation logic inherited from PrimaryProdDataServiceConsumerBase.
    function updatePrice() external {
        // Use the cache if the previous price is still fresh.
        if (block.timestamp < lastUpdatedAt + maxStaleness) return;

        uint256 price = getOracleNumericValueFromTxMsg(feedId);
        if (price > type(uint224).max) revert Errors.PriceOracle_Overflow();
        lastPrice = uint224(price);
        lastUpdatedAt = uint32(block.timestamp);
    }

    /// @notice Get the quote from the Redstone feed.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the Redstone feed.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        if (_base != base || _quote != quote) revert Errors.PriceOracle_NotSupported(_base, _quote);
        uint256 staleness = block.timestamp - lastUpdatedAt;
        if (staleness > maxStaleness) revert Errors.PriceOracle_TooStale(staleness, maxStaleness);

        if (inverse) return (inAmount * scaleFactor) / lastPrice;
        else return (inAmount * lastPrice) / scaleFactor;
    }
}
