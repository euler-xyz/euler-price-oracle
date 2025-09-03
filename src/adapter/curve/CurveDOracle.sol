// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {ScaleUtils, Scale} from "../../lib/ScaleUtils.sol";
import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {ICurveStableSwapNGPool} from "./ICurveStableSwapNGPool.sol";

/// @title CurveDOracle
/// @notice Adapter utilizing the lp token virtual price oracle in Curve pools.
contract CurveDOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "CurveDOracle";
    /// @notice The address of the Curve pool.
    address public immutable pool;
    /// @notice The address of the quote asset, must be `pool.coins[0]`.
    address public immutable quote;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;
    /// @notice Decimals of curve pool lp token.
    uint8 internal immutable lpDecimals;

    /// @notice Deploy a CurveDOracle.
    /// @param _pool The address of the Curve pool.
    /// @param _quoteIndex The quote asset index in Curve pool.
    /// Additionally, verify that the pool has enough liquidity before deploying this adapter.
    constructor(address _pool, uint256 _quoteIndex) {
        pool = _pool;
        quote = ICurveStableSwapNGPool(pool).coins(_quoteIndex);
        uint8 baseDecimals = _getDecimals(pool);
        uint8 quoteDecimals = _getDecimals(quote);

        lpDecimals = baseDecimals;
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, lpDecimals);
    }

    /// @notice Get a quote by calling the Curve oracle.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the Curve D oracle.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, pool, _quote, quote);

        uint256 dOracle = ICurveStableSwapNGPool(pool).D_oracle();
        uint256 totalSupply = ICurveStableSwapNGPool(pool).totalSupply();

        uint256 unitPrice = FixedPointMathLib.fullMulDiv(dOracle, 10 ** lpDecimals, totalSupply);

        return ScaleUtils.calcOutAmount(inAmount, unitPrice, scale, inverse);
    }
}
