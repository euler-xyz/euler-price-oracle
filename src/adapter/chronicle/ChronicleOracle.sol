// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {BaseAdapter} from "src/adapter/BaseAdapter.sol";
import {IChronicle} from "src/adapter/chronicle/IChronicle.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title ChronicleOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice PriceOracle adapter for Chronicle push-based price feeds.
contract ChronicleOracle is BaseAdapter {
    /// @notice The address of the base asset corresponding to the feed.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the feed
    address public immutable quote;
    /// @notice The address of the Chronicle price feed.
    /// @dev https://chroniclelabs.org/dashboard/oracles
    address public immutable feed;
    /// @notice The maximum allowed age of the price.
    /// @dev Reverts if age > maxStaleness.
    uint256 public immutable maxStaleness;
    /// @notice Whether the feed returns the price of base/quote or quote/base.
    bool public immutable inverse;
    /// @dev The scale factor used to convert decimals.
    uint256 internal immutable scaleFactor;
    /// @dev Whether the scale factor is applied to the numerator (true) or denominator (false).
    bool internal immutable scaleNumerator;

    /// @notice Deploy a ChronicleOracle.
    /// @param _base The address of the base asset corresponding to the feed.
    /// @param _quote The address of the quote asset corresponding to the feed.
    /// @param _feed The address of the Chronicle price feed.
    /// @param _maxStaleness The maximum allowed age of the price.
    /// @param _inverse Whether the feed returns the price of base/quote or quote/base.
    /// @dev Base and quote are not required to correspond to the feed assets.
    /// For example, the ETH/USD feed can be used to price WETH/USDC.
    constructor(address _base, address _quote, address _feed, uint256 _maxStaleness, bool _inverse) {
        base = _base;
        quote = _quote;
        feed = _feed;
        maxStaleness = _maxStaleness;
        inverse = _inverse;

        // The scale factor is used to correctly convert decimals.
        int8 baseDecimals = int8(ERC20(base).decimals());
        int8 quoteDecimals = int8(ERC20(quote).decimals());
        int8 feedDecimals = int8(IChronicle(feed).decimals());
        int8 scaleDecimals;
        if (inverse) {
            scaleDecimals = feedDecimals + quoteDecimals - baseDecimals;
        } else {
            scaleDecimals = feedDecimals + baseDecimals - quoteDecimals;
        }
        if (scaleDecimals > 0) {
            scaleFactor = 10 ** uint8(scaleDecimals);
            scaleNumerator = inverse;
        } else {
            scaleFactor = 10 ** uint8(-scaleDecimals);
            scaleNumerator = !inverse;
        }
    }

    /// @notice Get the quote from the Chronicle feed.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the Chronicle feed.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        if (_base != base || _quote != quote) revert Errors.PriceOracle_NotSupported(_base, _quote);

        (uint256 price, uint256 age) = IChronicle(feed).readWithAge();
        if (price == 0) revert Errors.PriceOracle_InvalidAnswer();
        if (age > maxStaleness) revert Errors.PriceOracle_TooStale(age, maxStaleness);

        if (scaleNumerator) return (inAmount * scaleFactor) / price;
        else return (inAmount * price) / scaleFactor;
    }
}
