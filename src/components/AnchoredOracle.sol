// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {BaseAdapter, Errors, IPriceOracle} from "src/adapter/BaseAdapter.sol";

/// @title AnchoredOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice PriceOracle that chains two PriceOracles.
contract AnchoredOracle is BaseAdapter {
    /// @notice The lower bound for `maxDivergence`, 0.1%.
    uint256 internal constant MAX_DIVERGENCE_LOWER_BOUND = 0.001e18;
    /// @notice The upper bound for `maxDivergence`, 50%.
    uint256 internal constant MAX_DIVERGENCE_UPPER_BOUND = 0.5e18;
    /// @notice The denominator for `maxDivergence`.
    uint256 internal constant WAD = 1e18;
    /// @notice The address of the primary oracle.
    address public immutable primaryOracle;
    /// @notice The address of the anchor oracle.
    address public immutable anchorOracle;
    /// @notice The maximum divergence allowed, denominated in WAD.
    uint256 public immutable maxDivergence;

    /// @notice Deploy an AnchoredOracle.
    /// @param _primaryOracle The oracle to use for the quote.
    /// @param _anchorOracle The oracle to use as an anchor.
    /// @param _maxDivergence The maximum divergence allowed, denominated in WAD.
    constructor(address _primaryOracle, address _anchorOracle, uint256 _maxDivergence) {
        if (_maxDivergence < MAX_DIVERGENCE_LOWER_BOUND || _maxDivergence > MAX_DIVERGENCE_UPPER_BOUND) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        primaryOracle = _primaryOracle;
        anchorOracle = _anchorOracle;
        maxDivergence = _maxDivergence;
    }

    /// @notice Get a quote from `primaryOracle` and verify it does not diverge too much from `anchorOracle`.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @return The quote returned by `primaryOracle`.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        uint256 outAmount = IPriceOracle(primaryOracle).getQuote(inAmount, base, quote);
        uint256 anchorOutAmount = IPriceOracle(anchorOracle).getQuote(inAmount, base, quote);

        if (outAmount < anchorOutAmount) {
            uint256 divergence = FixedPointMathLib.fullMulDivUp(outAmount, WAD, anchorOutAmount);
            if (divergence > maxDivergence) revert Errors.PriceOracle_InvalidAnswer();
        } else {
            uint256 divergence = FixedPointMathLib.fullMulDivUp(anchorOutAmount, WAD, outAmount);
            if (divergence > maxDivergence) revert Errors.PriceOracle_InvalidAnswer();
        }
        return outAmount;
    }
}
