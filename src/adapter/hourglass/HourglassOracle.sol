// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {ScaleUtils, Scale} from "../../lib/ScaleUtils.sol";
import {IHourglassDepositor} from "./IHourglassDepositor.sol";
import {IHourglassERC20TBT} from "./IHourglassERC20TBT.sol";

contract HourglassOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "HourglassOracle";

    /// @notice The number of decimals for the base token.
    uint256 internal immutable baseTokenScale;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice The address of the base asset (e.g., PT or CT).
    address public immutable base;
    /// @notice The address of the quote asset (e.g., underlying asset).
    address public immutable quote;

    /// @notice Per second discount rate (scaled by 1e18).
    uint256 public immutable discountRate;

    /// @notice Address of the Hourglass depositor contract (pool-specific).
    IHourglassDepositor public immutable hourglassDepositor;

    /// @notice The address of the combined token.
    address public immutable combinedToken;
    /// @notice The address of the principal token.
    address public immutable principalToken;
    /// @notice The address of the underlying token.
    address public immutable underlyingToken;

    /// @notice Deploy the HourglassLinearDiscountOracle.
    /// @param _base The address of the base asset (PT or CT).
    /// @param _quote The address of the quote asset (underlying token).
    /// @param _discountRate Discount rate (secondly, scaled by 1e18).
    constructor(address _base, address _quote, uint256 _discountRate) {
        if (_discountRate == 0) revert Errors.PriceOracle_InvalidConfiguration();

        // Initialize key parameters
        base = _base;
        quote = _quote;
        discountRate = _discountRate;
        hourglassDepositor = IHourglassDepositor(IHourglassERC20TBT(_base).depositor());

        // Fetch token addresses
        address[] memory tokens = hourglassDepositor.getTokens();
        combinedToken = tokens[0];
        principalToken = tokens[1];
        underlyingToken = hourglassDepositor.getUnderlying();

        // Only allow PT or CT as base token
        if (_base != combinedToken && _base != principalToken) revert Errors.PriceOracle_InvalidConfiguration();

        // Calculate scale factors for decimal conversions
        uint8 baseDecimals = _getDecimals(_base);
        uint8 quoteDecimals = _getDecimals(_quote);
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, quoteDecimals);
        baseTokenScale = 10 ** baseDecimals;
    }

    /// @notice Get a dynamic quote using linear discounting and solvency adjustment.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token being priced (e.g., PT or CT).
    /// @param _quote The token used as the unit of account (e.g., underlying).
    /// @return The converted amount using the linear discount rate and solvency adjustment.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        // Get solvency ratio, baseTokenDecimals precision
        uint256 solvencyRatio = _getSolvencyRatio();

        // Calculate present value using linear discounting, baseTokenDecimals precision
        uint256 presentValue = _getUnitPresentValue(solvencyRatio);

        // Return scaled output amount
        return ScaleUtils.calcOutAmount(inAmount, presentValue, scale, inverse);
    }

    /// @notice Calculate the present value using linear discounting.
    /// @param solvencyRatio Solvency ratio of the Hourglass system (scaled by baseTokenDecimals).
    /// @return presentValue The present value of the input amount (scaled by baseTokenDecimals).
    function _getUnitPresentValue(uint256 solvencyRatio) internal view returns (uint256) {
        uint256 maturityTime = hourglassDepositor.maturity();

        // Already matured, so PV = solvencyRatio.
        if (maturityTime <= block.timestamp) return solvencyRatio;

        uint256 timeToMaturity = maturityTime - block.timestamp;

        // The expression (1e18 + discountRate * timeToMaturity) is ~1e18 scale
        // We want the denominator to be scaled to baseTokenDecimals so that when
        // we divide the (inAmount * solvencyRatio) [which is 2 * baseTokenDecimals in scale],
        // we end up back with baseTokenDecimals in scale.

        uint256 scaledDenominator = (
            (1e18 + (discountRate * timeToMaturity)) // ~1e18 scale
                * baseTokenScale
        ) // multiply by 1e(baseTokenDecimals)
            / 1e18; // now scaledDenominator has baseTokenDecimals precision

        // (inAmount * solvencyRatio) is scale = 2 * baseTokenDecimals
        // dividing by scaledDenominator (scale = baseTokenDecimals)
        // => result has scale = baseTokenDecimals
        return (baseTokenScale * solvencyRatio) / scaledDenominator;
    }

    /// @notice Fetch the solvency ratio of the Hourglass system.
    /// @dev The ratio is capped to 1. The returned value is scaled by baseTokenDecimals.
    /// @return solvencyRatio Solvency ratio of the Hourglass system (scaled by baseTokenDecimals).
    function _getSolvencyRatio() internal view returns (uint256) {
        uint256 ptSupply = IERC20(principalToken).totalSupply();
        uint256 ctSupply = IERC20(combinedToken).totalSupply();
        uint256 totalClaims = ptSupply + ctSupply;
        if (totalClaims == 0) return baseTokenScale;

        uint256 underlyingTokenBalance = IERC20(underlyingToken).balanceOf(address(hourglassDepositor));

        // Return the solvency as a ratio capped to 1.
        if (underlyingTokenBalance < totalClaims) {
            return underlyingTokenBalance * baseTokenScale / totalClaims;
        } else {
            return baseTokenScale;
        }
    }
}
