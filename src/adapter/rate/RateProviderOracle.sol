// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {ScaleUtils, Scale} from "../../lib/ScaleUtils.sol";
import {IRateProvider} from "./IRateProvider.sol";

/// @title RateProviderOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice PriceOracle adapter for Balancer Rate Providers.
/// @dev See https://docs.balancer.fi/reference/contracts/rate-providers.html
contract RateProviderOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "RateProviderOracle";
    /// @notice The address of the base asset corresponding to the feed.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the feed.
    address public immutable quote;
    /// @notice The address of the Rate Provider contract.
    address public immutable rateProvider;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy a RateProviderOracle.
    /// @param _base The address of the base asset corresponding to the Rate Provider.
    /// @param _quote The address of the quote asset corresponding to the Rate Provider.
    /// @param _rateProvider The address of the Balancer Rate Provider contract.
    constructor(address _base, address _quote, address _rateProvider) {
        base = _base;
        quote = _quote;
        rateProvider = _rateProvider;
        uint8 quoteDecimals = _getDecimals(quote);
        // Since Balancer uses 18 decimals for internal accounting we override base decimals to 18.
        scale = ScaleUtils.calcScale(18, quoteDecimals, quoteDecimals);
    }

    /// @notice Get the quote from the Rate Provider feed.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the Rate Provider.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);
        uint256 rate = IRateProvider(rateProvider).getRate();
        if (rate == 0) revert Errors.PriceOracle_InvalidAnswer();
        return ScaleUtils.calcOutAmount(inAmount, rate, scale, inverse);
    }
}
