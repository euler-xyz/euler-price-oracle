// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseAdapter, Errors, IPriceOracle} from "../adapter/BaseAdapter.sol";
import {ScaleUtils, Scale} from "../lib/ScaleUtils.sol";

/// @title GrowthSentinel
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Wrapper component that caps the growth rate of an exchange rate oracle.
/// @dev If the rate exceeds the cap then the cap is returned.
contract GrowthSentinel is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "GrowthSentinel";
    /// @notice The address of the wrapped (underlying) oracle.
    address public immutable wrappedOracle;
    /// @notice The address of the base asset corresponding to the oracle.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the oracle.
    address public immutable quote;
    /// @notice The maximum per-second growth of the exchange rate.
    uint256 public immutable maxRateGrowth;
    /// @notice The unit exchange rate of base/quote taken at contract creation.
    uint256 public immutable snapshotRate;
    /// @notice The timestamp of the exchange rate snapshot.
    uint256 public immutable snapshotAt;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy a GrowthSentinel.
    /// @param _wrappedOracle The address of the underlying exchange rate oracle.
    /// @param _base The address of the base asset corresponding to the oracle.
    /// @param _quote The address of the quote asset corresponding to the oracle.
    /// @param _maxRateGrowth The maximum permitted growth of the exchange rate.
    constructor(address _wrappedOracle, address _base, address _quote, uint256 _maxRateGrowth) {
        wrappedOracle = _wrappedOracle;
        base = _base;
        quote = _quote;
        maxRateGrowth = _maxRateGrowth;

        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);

        snapshotRate = IPriceOracle(wrappedOracle).getQuote(10 ** baseDecimals, base, quote);
        snapshotAt = block.timestamp;
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, quoteDecimals);
    }

    /// @notice Get the maximum permitted current exchange rate.
    /// @return The maximum permitted unit exchange rate of base/quote.
    function maxRate() external view returns (uint256) {
        return maxRate(block.timestamp);
    }

    /// @notice Get the maximum permitted exchange rate at a timestamp.
    /// @param timestamp The timestamp to use. Must not be earlier than `snapshotAt`.
    /// @return The maximum permitted unit exchange rate of base/quote.
    function maxRate(uint256 timestamp) public view returns (uint256) {
        if (timestamp < snapshotAt) revert Errors.PriceOracle_InvalidAnswer();
        uint256 secondsElapsed = timestamp - snapshotAt;
        return snapshotRate + maxRateGrowth * secondsElapsed;
    }

    /// @notice Get the quote from the wrapped oracle and apply a cap to the rate.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the wrapped oracle, with its growth capped.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        uint256 outAmount = IPriceOracle(wrappedOracle).getQuote(inAmount, _base, _quote);
        uint256 capAmount = ScaleUtils.calcOutAmount(inAmount, maxRate(block.timestamp), scale, inverse);

        if (inverse) {
            return outAmount > capAmount ? outAmount : capAmount;
        }
        return outAmount < capAmount ? outAmount : capAmount;
    }
}
