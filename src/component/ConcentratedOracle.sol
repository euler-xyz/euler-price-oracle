// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {BaseAdapter, IPriceOracle} from "../adapter/BaseAdapter.sol";

/// @title ConcentratedOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Component that dampens the fluctuations of a market price around a peg.
/// @dev See Desmos: https://www.desmos.com/calculator/xwnz5uzomi
contract ConcentratedOracle is BaseAdapter {
    /// @notice 1e18 scalar used for precision.
    uint256 internal constant WAD = 1e18;
    /// @inheritdoc IPriceOracle
    string public constant name = "ConcentratedOracle";
    /// @notice The address of the base asset corresponding to the oracle.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the oracle.
    address public immutable quote;
    /// @notice The exchange rate oracle for base/quote.
    address public immutable fundamentalOracle;
    /// @notice The market price oracle for base/quote.
    address public immutable marketOracle;
    /// @notice Exponential decay constant.
    uint256 public immutable lambda;

    /// @notice Deploy a ConcentratedOracle.
    /// @param _base The address of the base asset corresponding to the oracle.
    /// @param _quote The address of the quote asset corresponding to the oracle.
    /// @param _fundamentalOracle The exchange rate oracle for base/quote.
    /// @param _marketOracle The market price oracle for base/quote.
    /// @param lambda Exponential decay constant.
    constructor(address _base, address _quote, address _fundamentalOracle, address _marketOracle, uint256 _lambda) {
        base = _base;
        quote = _quote;
        fundamentalOracle = _fundamentalOracle;
        marketOracle = _marketOracle;
        lambda = _lambda;
    }

    /// @notice Get a quote and concentrate it to the fundamental price based on deviation.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        // Fetch the market quote (m) and the fundamental quote (f).
        uint256 m = IPriceOracle(marketOracle).getQuote(inAmount, _base, _quote);
        uint256 f = IPriceOracle(fundamentalOracle).getQuote(inAmount, _base, _quote);
        if (f == 0) return 0;
        // Calculate the relative error ε = |f - m| / f.
        uint256 dist = f > m ? f - m : m - f;
        uint256 err = dist * WAD / f;
        // Calculate the weight of the fundamental quote w_f = exp(-λε).
        // Since the power is always negative, 0 ≤ w_f ≤ 1.
        int256 power = -int256(lambda * err);
        uint256 wf = uint256(FixedPointMathLib.expWad(power));
        // Apply the weights and return the result.
        return (f * wf + m * (WAD - wf)) / WAD;
    }
}
