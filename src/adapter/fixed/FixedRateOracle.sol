// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {ScaleUtils, Scale} from "../../lib/ScaleUtils.sol";

/// @title FixedRateOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice PriceOracle adapter that applies a fixed exchange rate.
contract FixedRateOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "FixedRateOracle";
    /// @notice The address of the base asset.
    address public immutable base;
    /// @notice The address of the quote asset.
    address public immutable quote;
    /// @notice The fixed conversion rate between base and quote.
    /// @dev Must be given in the quote asset's decimals.
    uint256 public immutable rate;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy a FixedRateOracle.
    /// @param _base The address of the base asset.
    /// @param _quote The address of the quote asset.
    /// @param _rate The fixed conversion rate between base and quote.
    /// @dev `_rate` must be given in the quote asset's decimals.
    constructor(address _base, address _quote, uint256 _rate) {
        if (_rate == 0) revert Errors.PriceOracle_InvalidConfiguration();
        base = _base;
        quote = _quote;
        rate = _rate;
        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, quoteDecimals);
    }

    /// @notice Get a quote by applying the fixed exchange rate.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the fixed exchange rate.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);
        return ScaleUtils.calcOutAmount(inAmount, rate, scale, inverse);
    }
}
