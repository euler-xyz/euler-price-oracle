// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseAdapter, Errors, IPriceOracle} from "../adapter/BaseAdapter.sol";
import {ScaleUtils, Scale} from "../lib/ScaleUtils.sol";

/// @title RangeSentinel
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Wrapper component that bounds an exchange rate to a range.
/// @dev Outside of the range the rate is saturated to the boundary.
contract RangeSentinel is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "RangeSentinel";
    /// @notice The address of the wrapped (underlying) oracle.
    address public immutable wrappedOracle;
    /// @notice The address of the base asset corresponding to the oracle.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the oracle.
    address public immutable quote;
    /// @notice The minimum unit exchange rate of base/quote.
    uint256 public immutable minRate;
    /// @notice The maximum unit exchange rate of base/quote.
    uint256 public immutable maxRate;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy a RangeSentinel.
    /// @param _wrappedOracle The address of the underlying exchange rate oracle.
    /// @param _base The address of the base asset corresponding to the oracle.
    /// @param _quote The address of the quote asset corresponding to the oracle.
    /// @param _minRate The minimum unit exchange rate of base/quote.
    /// @param _maxRate The maximum unit exchange rate of base/quote.
    constructor(address _wrappedOracle, address _base, address _quote, uint256 _minRate, uint256 _maxRate) {
        if (_minRate > _maxRate || _minRate == 0) revert Errors.PriceOracle_InvalidConfiguration();
        wrappedOracle = _wrappedOracle;
        base = _base;
        quote = _quote;
        minRate = _minRate;
        maxRate = _maxRate;
    }

    /// @notice Get the quote from the wrapped oracle and bound it to the range.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the wrapped oracle, bounded to the range.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        uint256 outAmount = IPriceOracle(wrappedOracle).getQuote(inAmount, _base, _quote);
        uint256 minAmount = ScaleUtils.calcOutAmount(inAmount, minRate, scale, inverse);
        uint256 maxAmount = ScaleUtils.calcOutAmount(inAmount, maxRate, scale, inverse);

        if (outAmount < minAmount) return minAmount;
        if (outAmount > maxAmount) return maxAmount;
        return outAmount;
    }
}
