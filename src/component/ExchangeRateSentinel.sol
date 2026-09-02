// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseAdapter, Errors, IPriceOracle} from "../adapter/BaseAdapter.sol";
import {ScaleUtils, Scale} from "../lib/ScaleUtils.sol";

/// @title ExchangeRateSentinel
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice The sentinel is used to clamp the exchange rate and constrain its growth.
/// @dev If out of bounds the rate is saturated (clamped) to the boundary.
contract ExchangeRateSentinel is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "ExchangeRateSentinel";
    /// @notice The address of the underlying oracle.
    address public immutable oracle;
    /// @notice The address of the base asset corresponding to the oracle.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the oracle.
    address public immutable quote;
    /// @notice The lower bound for the unit exchange rate of base/quote.
    /// @dev Below this value the exchange rate is saturated (returns the floor).
    uint256 public immutable floorRate;
    /// @notice The upper bound for the unit exchange rate of base/quote.
    /// @dev Above this value the exchange rate is saturated (returns the ceil).
    uint256 public immutable ceilRate;
    /// @notice The maximum per-second growth of the exchange rate.
    /// @dev Relative to the snapshotted rate at deployment.
    /// If the value is `type(uint256).max` then growth bounds are disabled.
    uint256 public immutable maxRateGrowth;
    /// @notice The unit exchange rate of base/quote taken at deployment.
    uint256 public immutable snapshotRate;
    /// @notice The timestamp of the exchange rate snapshot.
    uint256 public immutable snapshotAt;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy an ExchangeRateSentinel.
    /// @param _oracle The address of the underlying oracle.
    /// @param _base The address of the base asset corresponding to the oracle.
    /// @param _quote The address of the quote asset corresponding to the oracle.
    /// @param _floorRate The minimum unit exchange rate of base/quote.
    /// @param _ceilRate The maximum unit exchange rate of base/quote.
    /// @param _maxRateGrowth The maximum per-second growth of the exchange rate.
    /// @dev To use absolute bounds only, set `_maxRateGrowth` to `type(uint256).max`.
    /// To use growth bounds only, set `_floorRate` to 0 and `_ceilRate` to `type(uint256).max`.
    constructor(
        address _oracle,
        address _base,
        address _quote,
        uint256 _floorRate,
        uint256 _ceilRate,
        uint256 _maxRateGrowth
    ) {
        if (_floorRate > _ceilRate) revert Errors.PriceOracle_InvalidConfiguration();
        oracle = _oracle;
        base = _base;
        quote = _quote;
        floorRate = _floorRate;
        ceilRate = _ceilRate;
        maxRateGrowth = _maxRateGrowth;

        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);

        // Snapshot the unit exchange rate at deployment.
        snapshotRate = IPriceOracle(oracle).getQuote(10 ** baseDecimals, base, quote);
        snapshotAt = block.timestamp;
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, quoteDecimals);
    }

    /// @notice Get the upper bound of the unit exchange rate of base/quote.
    /// @dev This value is either bound by `maxRate` or `maxRateGrowth`.
    /// @return The current maximum exchange rate.
    function maxRate() external view returns (uint256) {
        return _maxRateAt(block.timestamp);
    }

    /// @notice Get the upper bound of the unit exchange rate of base/quote at a timestamp.
    /// @param timestamp The timestamp to use. Must not be earlier than `snapshotAt`.
    /// @return The maximum unit exchange rate of base/quote at the given timestamp.
    function _maxRateAt(uint256 timestamp) internal view returns (uint256) {
        // If growth bounds are disabled then only the absolute bounds apply.
        if (maxRateGrowth == type(uint256).max) return ceilRate;
        // Protect against inconsistent timing on non-standard EVMs.
        if (timestamp < snapshotAt) revert Errors.PriceOracle_InvalidAnswer();
        // Return the smaller of the absolute bound and the growth bound.
        uint256 secondsElapsed = timestamp - snapshotAt;
        uint256 max = snapshotRate + maxRateGrowth * secondsElapsed;
        return max < ceilRate ? max : ceilRate;
    }

    /// @notice Get the quote from the wrapped oracle and bound it to the range.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the wrapped oracle, bounded to the range.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        uint256 outAmount = IPriceOracle(oracle).getQuote(inAmount, _base, _quote);
        uint256 minAmount = ScaleUtils.calcOutAmount(inAmount, floorRate, scale, inverse);
        uint256 maxAmount = ScaleUtils.calcOutAmount(inAmount, _maxRateAt(block.timestamp), scale, inverse);

        // If inverse route then flip the limits because they are specified per unit base/quote by convention.
        (minAmount, maxAmount) = inverse ? (maxAmount, minAmount) : (minAmount, maxAmount);
        if (outAmount < minAmount) return minAmount;
        if (outAmount > maxAmount) return maxAmount;
        return outAmount;
    }
}
