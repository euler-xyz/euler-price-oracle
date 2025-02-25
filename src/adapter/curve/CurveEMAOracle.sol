// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ScaleUtils, Scale} from "../../lib/ScaleUtils.sol";
import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {ICurvePool} from "./ICurvePool.sol";

/// @title CurveEMAOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter utilizing the EMA price oracle in Curve pools.
contract CurveEMAOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "CurveEMAOracle";
    /// @notice The address of the Curve pool.
    address public immutable pool;
    /// @notice The address of the base asset.
    address public immutable base;
    /// @notice The address of the quote asset, must be `pool.coins[0]`.
    address public immutable quote;
    /// @notice The index in `price_oracle` corresponding to the base asset.
    /// @dev Note that indices in `price_oracle` are shifted by 1, i.e. `0` corresponds to `coins[1]`.
    /// @dev If type(uint256).max, then the adapter will call `price_oracle()`.
    /// @dev Else the adapter will call the indexed price method `price_oracle(priceOracleIndex)`.
    uint256 public immutable priceOracleIndex;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy a CurveEMAOracle.
    /// @param _pool The address of the Curve pool.
    /// @param _base The address of the base asset.
    /// @param _priceOracleIndex The index in `price_oracle` corresponding to the base asset.
    /// @dev The quote is always `pool.coins[0]`.
    /// If `priceOracleIndex` is `type(uint256).max`, then the adapter will call the non-indexed price method `price_oracle()`
    /// WARNING: Some StableSwap-NG pools deployed before Dec-12-2023 have a known oracle vulerability.
    /// See (https://docs.curve.fi/stableswap-exchange/stableswap-ng/pools/oracles/#price-oracles) for more details.
    /// Additionally, verify that the pool has enough liquidity before deploying this adapter.
    constructor(address _pool, address _base, uint256 _priceOracleIndex) {
        pool = _pool;
        base = _base;
        // The EMA oracle returns a price quoted in `coins[0]`.
        quote = ICurvePool(_pool).coins(0);
        priceOracleIndex = _priceOracleIndex;
        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, 18);
    }

    /// @notice Get a quote by calling the Curve oracle.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the Curve EMA oracle.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        uint256 unitPrice;
        if (priceOracleIndex == type(uint256).max) {
            unitPrice = ICurvePool(pool).price_oracle();
        } else {
            unitPrice = ICurvePool(pool).price_oracle(priceOracleIndex);
        }

        return ScaleUtils.calcOutAmount(inAmount, unitPrice, scale, inverse);
    }
}
