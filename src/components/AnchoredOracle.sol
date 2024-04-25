// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {BaseAdapter, Errors, IPriceOracle} from "src/adapter/BaseAdapter.sol";

/// @title AnchoredOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice PriceOracle that chains two PriceOracles.
contract AnchoredOracle is BaseAdapter {
    /// @notice The lower bound for `maxDivergence`, 0.1%.
    uint256 internal constant DIVERGENCE_LOWER_BOUND = 0.001e18;
    /// @notice The upper bound for `maxDivergence`, 50%.
    uint256 internal constant DIVERGENCE_UPPER_BOUND = 0.5e18;
    /// @notice The denominator for `maxDivergence`.
    uint256 internal constant WAD = 1e18;
    /// @notice The address of the base asset.
    address public immutable base;
    /// @notice The address of the quote asset.
    address public immutable quote;
    /// @notice The address of the primary oracle.
    address public immutable oracle;
    /// @notice The address of the anchor oracle.
    address public immutable anchorOracle;
    /// @notice The maximum divergence allowed, denominated in WAD.
    uint256 public immutable maxDivergence;

    /// @notice Deploy a AnchoredOracle.
    /// @param _base The address of the base asset.
    /// @param _quote The address of the quote asset.
    /// @param _oracle The oracle to use for the price.
    /// @param _anchorOracle The oracle to use as an anchor.
    /// @param _maxDivergence The maximum divergence allowed, denominated in WAD.
    constructor(address _base, address _quote, address _oracle, address _anchorOracle, uint256 _maxDivergence) {
        if (_maxDivergence < DIVERGENCE_LOWER_BOUND || _maxDivergence > DIVERGENCE_UPPER_BOUND) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        base = _base;
        quote = _quote;
        oracle = _oracle;
        anchorOracle = _anchorOracle;
        maxDivergence = _maxDivergence;
    }

    /// @notice Get a quote by chaining the cross oracles.
    /// For the forward direction it calculates base/cross * cross/quote.
    /// For the inverse direction it calculates quote/cross * cross/base.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount by chaining the cross oracles.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        uint256 outAmount = IPriceOracle(oracle).getQuote(inAmount, _base, _quote);
        uint256 anchorOutAmount = IPriceOracle(anchorOracle).getQuote(inAmount, _base, _quote);

        if (outAmount < anchorOutAmount) {
            uint256 divergence = FixedPointMathLib.mulDivUp(outAmount, WAD, anchorOutAmount);
            if (divergence > maxDivergence) revert Errors.PriceOracle_InvalidAnswer();
        } else {
            uint256 divergence = FixedPointMathLib.mulDivUp(anchorOutAmount, WAD, outAmount);
            if (divergence > maxDivergence) revert Errors.PriceOracle_InvalidAnswer();
        }
        return outAmount;
    }
}
