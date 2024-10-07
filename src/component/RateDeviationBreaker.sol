// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseAdapter, Errors, IPriceOracle} from "../adapter/BaseAdapter.sol";
import {ScaleUtils, Scale} from "../lib/ScaleUtils.sol";

/// @title RateDeviationBreaker
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Component that can detect and react to a depeg.
contract RateDeviationBreaker is BaseAdapter {
    uint256 internal constant WAD = 1e18;
    /// @inheritdoc IPriceOracle
    string public constant name = "RateDeviationBreaker";
    /// @notice The address of the base asset corresponding to the oracle.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the oracle.
    address public immutable quote;
    /// @notice The exchange rate oracle.
    address public immutable exchangeRateOracle;
    /// @notice The market price oracle.
    address public immutable marketPriceOracle;
    /// @notice The scale factors used for decimal conversions.
    uint256 public immutable disableThreshold;
    uint256 public immutable switchThreshold;
    Scale internal immutable scale;

    /// @notice Deploy a GrowthSentinel.
    /// @param _base The address of the base asset corresponding to the oracle.
    /// @param _quote The address of the quote asset corresponding to the oracle.
    constructor(
        address _base,
        address _quote,
        address _exchangeRateOracle,
        address _marketPriceOracle,
        uint256 _disableThreshold,
        uint256 _switchThreshold
    ) {
        base = _base;
        quote = _quote;
        exchangeRateOracle = _exchangeRateOracle;
        marketPriceOracle = _marketPriceOracle;
        disableThreshold = _disableThreshold;
        switchThreshold = _switchThreshold;

        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, quoteDecimals);
    }

    /// @notice Get the quote from the wrapped oracle and apply a cap to the rate.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the wrapped oracle, with its growth capped.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        uint256 exchangeRateQuote = IPriceOracle(exchangeRateOracle).getQuote(inAmount, _base, _quote);
        uint256 marketPriceQuote = IPriceOracle(marketPriceOracle).getQuote(inAmount, _base, _quote);

        uint256 ratio = marketPriceQuote * WAD / exchangeRateQuote;

        // Disable oracle if the discount is too large.
        if (ratio < disableThreshold) revert Errors.PriceOracle_InvalidAnswer();
        // Switch to market price if there is a large discount.
        if (ratio < switchThreshold) return marketPriceQuote;
        // Under normal operation return the exchange rate.
        return exchangeRateQuote;
    }
}
