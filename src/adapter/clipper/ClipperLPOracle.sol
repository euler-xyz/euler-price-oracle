// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {ScaleUtils} from "../../lib/ScaleUtils.sol";
import {IClipperLP} from "./IClipperLP.sol";

/// @title ClipperLPOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing Clipper DEX LP Tokens.
/// WARNING: READ THIS BEFORE DEPLOYING
/// Ensure that the selected quote token has a sufficient decimal precision (e.g., 18 decimals).
/// Low-precision tokens like USDC (6 decimals) may lead to significant rounding errors when computing LP token unit prices.
/// For example, if the price of one LP token is close to or below the smallest unit of the quote token (e.g., 1e-6 for USDC),
/// the computed unit price may round down to zero, potentially resulting in inaccurate or zero value quotes.
/// To avoid this, select a quote token with high precision or ensure the LP token price is orders of magnitude above the quote token unit.
contract ClipperLPOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "ClipperLPOracle";
    /// @notice The address of the Clipper LP token.
    address public immutable lpToken;
    /// @notice The address of the quote asset.
    address public immutable quote;
    /// @notice The address of the oracle used to price pool tokens.
    /// @dev Must support pricing all pool tokens against USD e.g. an `EulerRouter` instance.
    address public immutable oracle;

    /// @notice Deploy a ClipperLPOracle.
    /// @param _lpToken The address of the Clipper LP token.
    /// @param _quote The address of the quote asset corresponding to the feed.
    /// @param _oracle The address of the oracle used to price pool tokens.
    constructor(address _lpToken, address _quote, address _oracle) {
        lpToken = _lpToken;
        quote = _quote;
        oracle = _oracle;
    }

    /// @notice Get the quote by decomposing the LP token and pricing its underlying.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, lpToken, _quote, quote);

        (uint256[] memory balances, address[] memory tokens, uint256 totalSupply) =
            IClipperLP(lpToken).allTokensBalance();

        // Cannot return a meaningful price if the LP token has 0 supply.
        if (totalSupply == 0) revert Errors.PriceOracle_InvalidAnswer();

        // Price each underlying token using the configured oracle.
        uint256 nTokens = balances.length;
        uint256 totalValue;
        for (uint256 i; i < nTokens; ++i) {
            uint256 balance = balances[i];
            if (balance == 0) continue; // Value will be 0, so skip the call.
            totalValue += IPriceOracle(oracle).getQuote(balance, tokens[i], quote);
        }

        if (inverse) {
            // Pricing `quote` to `lpToken`.
            return FixedPointMathLib.fullMulDiv(inAmount, totalSupply, totalValue);
        } else {
            // Pricing `lpToken` to `quote`.
            return FixedPointMathLib.fullMulDiv(inAmount, totalValue, totalSupply);
        }
    }
}
