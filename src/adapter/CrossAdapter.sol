// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {BaseAdapter} from "src/adapter/BaseAdapter.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {ScaleUtils, Scale} from "src/lib/ScaleUtils.sol";

/// @title CrossAdapter
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice PriceOracle that chains two adapters.
/// @dev For example, CrossAdapter can price wstETH/USD by querying a wstETH/stETH oracle and a stETH/USD oracle.
contract CrossAdapter is BaseAdapter {
    /// @notice The address of the base asset.
    address public immutable base;
    /// @notice The address of the cross/through asset.
    address public immutable cross;
    /// @notice The address of the quote asset.
    address public immutable quote;
    /// @notice The oracle that resolves base/cross and cross/base.
    /// @dev The oracle MUST be bidirectional.
    address public immutable oracleBaseCross;
    /// @notice The oracle that resolves quote/cross and cross/quote.
    /// @dev The oracle MUST be bidirectional.
    address public immutable oracleQuoteCross;

    /// @notice Deploy a CrossAdapter.
    /// @param _base The address of the base asset.
    /// @param _cross The address of the cross/through asset.
    /// @param _quote The address of the quote asset.
    /// @param _oracleBaseCross The oracle that resolves base/cross and cross/base.
    /// @param _oracleQuoteCross The oracle that resolves quote/cross and cross/quote.
    /// @dev Both cross oracles MUST be bidirectional.
    /// @dev Does not support bid/ask pricing.
    constructor(address _base, address _cross, address _quote, address _oracleBaseCross, address _oracleQuoteCross) {
        base = _base;
        cross = _cross;
        quote = _quote;
        oracleBaseCross = _oracleBaseCross;
        oracleQuoteCross = _oracleQuoteCross;
    }

    /// @notice Get a quote by chaining the cross oracles.
    /// For the forward direction it calculates base/cross * cross/quote.
    /// For the inverse direction it calculates quote/cross * cross/base.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount by chaining the cross oracles.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        if (inverse) {
            inAmount = IPriceOracle(oracleQuoteCross).getQuote(inAmount, quote, cross);
            return IPriceOracle(oracleBaseCross).getQuote(inAmount, cross, base);
        } else {
            inAmount = IPriceOracle(oracleBaseCross).getQuote(inAmount, base, cross);
            return IPriceOracle(oracleQuoteCross).getQuote(inAmount, cross, quote);
        }
    }
}
