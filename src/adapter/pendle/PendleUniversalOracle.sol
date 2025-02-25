// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IPMarket} from "@pendle/core-v2/interfaces/IPMarket.sol";
import {IPPrincipalToken} from "@pendle/core-v2/interfaces/IPPrincipalToken.sol";
import {IPPYLpOracle} from "@pendle/core-v2/interfaces/IPPYLpOracle.sol";
import {IStandardizedYield} from "@pendle/core-v2/interfaces/IStandardizedYield.sol";
import {PendlePYOracleLib} from "@pendle/core-v2/oracles/PendlePYOracleLib.sol";
import {PendleLpOracleLib} from "@pendle/core-v2/oracles/PendleLpOracleLib.sol";
import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {ScaleUtils, Scale} from "../../lib/ScaleUtils.sol";

/// @title PendleUniversalOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for Pendle PT and LP Oracle.
contract PendleUniversalOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "PendleUniversalOracle";
    /// @dev The minimum length of the TWAP window.
    uint32 internal constant MIN_TWAP_WINDOW = 5 minutes;
    /// @dev The maximum length of the TWAP window.
    uint32 internal constant MAX_TWAP_WINDOW = 60 minutes;
    /// @notice The decimals of the Pendle Oracle. Fixed to 18.
    uint8 internal constant FEED_DECIMALS = 18;
    /// @notice The address of the Pendle market.
    address public immutable pendleMarket;
    /// @notice The desired length of the twap window.
    uint32 public immutable twapWindow;
    /// @notice The address of the base asset, the PT address.
    address public immutable base;
    /// @notice The address of the quote asset, the SY or underlying address.
    address public immutable quote;
    /// @notice The PendlePYOracleLib function to call.
    function (IPMarket, uint32) view returns (uint256) internal immutable getRate;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy a PendleUniversalOracle.
    /// @dev The oracle can price Pendle PT,LP to SY,Asset. Whether to use SY or Asset depends on the underlying.
    /// Consult https://docs.pendle.finance/Developers/Contracts/StandardizedYield#standard-sys for more information.
    /// Before deploying this adapter ensure that the oracle is initialized and the observation buffer is filled.
    /// Note that this adapter allows specifing any `quote` as the underlying asset.
    /// @param _pendleOracle The address of the PendlePYLpOracle contract. Used only in the constructor.
    /// @param _pendleMarket The address of the Pendle market.
    /// @param _base The address of the PT or LP token.
    /// @param _quote The address of the SY token or the underlying asset.
    /// @param _twapWindow The desired length of the twap window.
    constructor(address _pendleOracle, address _pendleMarket, address _base, address _quote, uint32 _twapWindow) {
        // Verify that the TWAP window is sufficiently long.
        if (_twapWindow < MIN_TWAP_WINDOW || _twapWindow > MAX_TWAP_WINDOW) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        // Verify that the observations buffer is adequately sized and populated.
        (bool increaseCardinalityRequired,, bool oldestObservationSatisfied) =
            IPPYLpOracle(_pendleOracle).getOracleState(_pendleMarket, _twapWindow);
        if (increaseCardinalityRequired || !oldestObservationSatisfied) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        (IStandardizedYield sy, IPPrincipalToken pt,) = IPMarket(_pendleMarket).readTokens();

        // Note: we allow using any asset pricing to any token.
        if (_base == address(pt)) {
            if (_quote == address(sy)) {
                getRate = PendlePYOracleLib.getPtToSyRate;
            } else {
                getRate = PendlePYOracleLib.getPtToAssetRate;
            }
        } else if (_base == _pendleMarket) {
            if (_quote == address(sy)) {
                getRate = PendleLpOracleLib.getLpToSyRate;
            } else {
                getRate = PendleLpOracleLib.getLpToAssetRate;
            }
        } else {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        pendleMarket = _pendleMarket;
        base = _base;
        quote = _quote;
        twapWindow = _twapWindow;
        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, FEED_DECIMALS);
    }

    /// @notice Get a quote by calling the Pendle oracle.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @dev Note that the quote does not include instantaneous DEX slippage.
    /// @return The converted amount using the Pendle oracle.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);
        uint256 unitPrice = getRate(IPMarket(pendleMarket), twapWindow);
        return ScaleUtils.calcOutAmount(inAmount, unitPrice, scale, inverse);
    }
}
