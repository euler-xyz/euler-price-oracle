// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IPMarket} from "@pendle/core-v2/interfaces/IPMarket.sol";
import {IPPrincipalToken} from "@pendle/core-v2/interfaces/IPPrincipalToken.sol";
import {IPPYLpOracle} from "@pendle/core-v2/interfaces/IPPYLpOracle.sol";
import {IStandardizedYield} from "@pendle/core-v2/interfaces/IStandardizedYield.sol";
import {PendlePYOracleLib} from "@pendle/core-v2/oracles/PtYtLpOracle/PendlePYOracleLib.sol";
import {PendleLpOracleLib} from "@pendle/core-v2/oracles/PtYtLpOracle/PendleLpOracleLib.sol";
import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {ScaleUtils, Scale} from "../../lib/ScaleUtils.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/// @title PendleUnifiedOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for Pendle PT and LP Oracle.
contract PendleUnifiedOracle is BaseAdapter, Ownable2Step {
    /// @inheritdoc IPriceOracle
    string public constant name = "PendleUnifiedOracle";
    /// @dev The minimum length of the TWAP window.
    uint32 internal constant MIN_TWAP_WINDOW = 5 minutes;
    /// @dev The maximum length of the TWAP window.
    uint32 internal constant MAX_TWAP_WINDOW = 60 minutes;
    /// @notice The decimals of the Pendle Oracle. Fixed to 18.
    uint8 internal constant FEED_DECIMALS = 18;

    struct PairParams {
        /// @notice The address of the Pendle market.
        address pendleMarket;
        /// @notice The desired length of the twap window.
        uint32 twapWindow;
        /// @notice The flag indicating the direction of the price. False when base/quote, true - quote/base
        bool inverse;
        /// @notice The PendlePYOracleLib function to call.
        function (IPMarket, uint32) view returns (uint256) getRate;
        /// @notice The scale factors used for decimal conversions.
        Scale scale;
    }

    mapping(address => mapping(address => PairParams)) private _configuredPairs;

    address public immutable pendleOracle;

    event PairAdded(address indexed pendleMarket, address indexed base, address indexed quote, uint32 twapWindow);

    constructor(address _pendleOracle) {
        if (_pendleOracle == address(0)) {
            revert Errors.ZeroAddress();
        }

        pendleOracle = _pendleOracle;
    }

    /// @dev The oracle can price Pendle PT,LP to SY,Asset. Whether to use SY or Asset depends on the underlying.
    /// Consult https://docs.pendle.finance/Developers/Contracts/StandardizedYield#standard-sys for more information.
    /// Before deploying this adapter ensure that the oracle is initialized and the observation buffer is filled.
    /// Note that this adapter allows specifing any `quote` as the underlying asset.
    /// @param _pendleMarket The address of the Pendle market.
    /// @param _base The address of the PT or LP token.
    /// @param _quote The address of the SY token or the underlying asset.
    /// @param _twapWindow The desired length of the twap window.
    function addPair(address _pendleMarket, address _base, address _quote, uint32 _twapWindow) external onlyOwner {
        //Verify that the pair is not already initialized.
        if (_configuredPairs[_base][_quote].pendleMarket != address(0)) {
            revert Errors.PriceOracle_AlreadyInitialized();
        }

        // Verify that the TWAP window is sufficiently long.
        if (_twapWindow < MIN_TWAP_WINDOW || _twapWindow > MAX_TWAP_WINDOW) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        // Verify that the observations buffer is adequately sized and populated.
        (bool increaseCardinalityRequired,, bool oldestObservationSatisfied) =
            IPPYLpOracle(pendleOracle).getOracleState(_pendleMarket, _twapWindow);
        if (increaseCardinalityRequired || !oldestObservationSatisfied) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        (IStandardizedYield sy, IPPrincipalToken pt,) = IPMarket(_pendleMarket).readTokens();
        (, address asset,) = sy.assetInfo();

        PairParams memory pairParams;

        if (_base == address(pt)) {
            if (_quote == address(sy)) {
                pairParams.getRate = PendlePYOracleLib.getPtToSyRate;
            } else if (asset == _quote) {
                // Pendle do not recommend to use this type of price
                // https://docs.pendle.finance/Developers/Oracles/HowToIntegratePtAndLpOracle
                pairParams.getRate = PendlePYOracleLib.getPtToAssetRate;
            } else {
                revert Errors.PriceOracle_InvalidConfiguration();
            }
        } else if (_base == _pendleMarket) {
            if (_quote == address(sy)) {
                pairParams.getRate = PendleLpOracleLib.getLpToSyRate;
            } else if (asset == _quote) {
                pairParams.getRate = PendleLpOracleLib.getLpToAssetRate;
            } else {
                revert Errors.PriceOracle_InvalidConfiguration();
            }
        } else {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        pairParams.pendleMarket = _pendleMarket;
        pairParams.twapWindow = _twapWindow;
        pairParams.inverse = false;

        // We don't need to worry about decimals base and quote decimals scaling,
        // Pendle formula to access LP (rawX) in SY (rawY)
        // rawY= rawX × lpToSyRate / 10^18
        //
        // https://docs.pendle.finance/Developers/Oracles/HowToIntegratePtAndLpOracle
        pairParams.scale = ScaleUtils.calcScale(0, 0, FEED_DECIMALS);

        _configuredPairs[_base][_quote] = pairParams;

        pairParams.inverse = true;
        _configuredPairs[_quote][_base] = pairParams;

        emit PairAdded(_pendleMarket, _base, _quote, _twapWindow);
    }

    /// @notice Get a quote by calling the Pendle oracle.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @dev Note that the quote does not include instantaneous DEX slippage.
    /// @return The converted amount using the Pendle oracle.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        PairParams memory pairParams = _configuredPairs[_base][_quote];
        if (pairParams.pendleMarket == address(0)) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        uint256 unitPrice = pairParams.getRate(IPMarket(pairParams.pendleMarket), pairParams.twapWindow);
        return ScaleUtils.calcOutAmount(inAmount, unitPrice, pairParams.scale, pairParams.inverse);
    }

    function getConfiguredPair(address _base, address _quote)
        external
        view
        returns (address pendleMarket, uint32 twapWindow, bool inverse, Scale scale)
    {
        PairParams memory pairParams = _configuredPairs[_base][_quote];
        return (pairParams.pendleMarket, pairParams.twapWindow, pairParams.inverse, pairParams.scale);
    }
}
