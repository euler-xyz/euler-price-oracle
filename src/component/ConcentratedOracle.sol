// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {BaseAdapter, IPriceOracle} from "../adapter/BaseAdapter.sol";

/// @title ConcentratedOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Component that concentrates a market price around the exchange rate.
/// @dev See Desmos: https://www.desmos.com/calculator/dzet62w513
contract ConcentratedOracle is BaseAdapter {
    uint256 internal constant WAD = 1e18;
    /// @inheritdoc IPriceOracle
    string public constant name = "RateDeviationBreaker";
    /// @notice The address of the base asset corresponding to the oracle.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the oracle.
    address public immutable quote;
    /// @notice The exchange rate oracle.
    address public immutable fundamentalOracle;
    /// @notice The market price oracle.
    address public immutable marketOracle;
    /// @notice Exponential decay constant.
    uint256 public immutable lambda;

    /// @notice Deploy a ConcentratedOracle.
    /// @param _base The address of the base asset corresponding to the oracle.
    /// @param _quote The address of the quote asset corresponding to the oracle.
    constructor(address _base, address _quote, address _fundamentalOracle, address _marketOracle, uint256 _lambda) {
        base = _base;
        quote = _quote;
        fundamentalOracle = _fundamentalOracle;
        marketOracle = _marketOracle;
        lambda = _lambda;
    }

    /// @notice Get the quote from the wrapped oracle and apply a cap to the rate.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the wrapped oracle, with its growth capped.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        // Fetch the market quote (m) and the fundamental quote (f).
        uint256 m = IPriceOracle(marketOracle).getQuote(inAmount, _base, _quote);
        uint256 f = IPriceOracle(fundamentalOracle).getQuote(inAmount, _base, _quote);
        if (f == 0) return 0;
        // Calculate the relative error ε = |f - m| / f.
        uint256 dist = f > m ? f - m : m - f;
        uint256 err = (dist * 1e18) / f;
        // Calculate the weight of the fundamental quote w_f = exp(-λε).
        // Since the power is always negative, 0 ≤ w_f ≤ 1.
        int256 power = -int256(lambda * err);
        uint256 wf = uint256(FixedPointMathLib.expWad(power));
        // Apply the weights and return the result.
        return (f * wf + m * (1e18 - wf)) / 1e18;
    }
}
