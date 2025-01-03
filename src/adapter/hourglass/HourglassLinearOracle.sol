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

    /// @notice The address of the base asset (e.g., PT or CT).
    address public immutable base;
    /// @notice The address of the quote asset (e.g., underlying asset).
    address public immutable quote;

    /// @notice Per second discount rate (scaled by baseAssetDecimals).
    uint256 public immutable discountRate;

    /// @notice Address of the Hourglass system.
    IHourglassDepositor public immutable hourglassDepositor;

    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice The address of the combined token.
    address public immutable combinedToken;
    /// @notice The address of the principal token.
    address public immutable principalToken;
    /// @notice The address of the underlying token.
    address public immutable underlyingToken;

    /// @notice The number of decimals for the base token.
    uint8 public immutable baseTokenDecimals;
    /// @notice The number of decimals for the quote token.
    uint8 public immutable quoteTokenDecimals;

    /// @notice Deploy the HourglassLinearDiscountOracle.
    /// @param _base The address of the base asset (PT or CT).
    /// @param _quote The address of the quote asset (underlying token).
    /// @param _discountRate Discount rate (secondly, scaled by baseAssetDecimals).
    constructor(address _base, address _quote, uint256 _discountRate) {
        if (_discountRate == 0) revert Errors.PriceOracle_InvalidConfiguration();

        // Initialize key parameters
        base = _base;
        quote = _quote;
        discountRate = _discountRate;

        // Fetch and store Hourglass depositor
        hourglassDepositor = IHourglassDepositor(IHourglassERC20TBT(_base).depositor());

        // Fetch token decimals
        uint8 baseDecimals = _getDecimals(_base);
        uint8 quoteDecimals = _getDecimals(_quote);

        // Fetch token addresses
        address[] memory tokens = hourglassDepositor.getTokens();
        combinedToken = tokens[0];
        principalToken = tokens[1];
        underlyingToken = hourglassDepositor.getUnderlying();

        // Calculate scale factors for decimal conversions
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, quoteDecimals);

        // Store decimals for normalization
        baseTokenDecimals = baseDecimals;
        quoteTokenDecimals = quoteDecimals;
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
        uint256 presentValue = _getPresentValue(inAmount, solvencyRatio);

        // Return scaled output amount
        return ScaleUtils.calcOutAmount(inAmount, presentValue, scale, inverse);
    }

    /// @notice Calculate the present value using linear discounting.
    /// @param inAmount The input amount of base tokens (scaled by baseTokenDecimals).
    /// @param solvencyRatio Solvency ratio of the Hourglass system (scaled by baseTokenDecimals).
    /// @return presentValue The present value of the input amount (scaled by baseTokenDecimals).
    function _getPresentValue(uint256 inAmount, uint256 solvencyRatio) internal view returns (uint256 presentValue) {
        uint256 baseTokenScale = 10 ** baseTokenDecimals;
        uint256 timeToMaturity = _getTimeToMaturity();
        uint256 discountFactor =
            (baseTokenScale * baseTokenScale) / (baseTokenScale + ((discountRate * timeToMaturity)));

        presentValue = (inAmount * solvencyRatio * discountFactor) / (baseTokenScale * baseTokenScale);
    }

    /// @notice Fetch the time-to-maturity.
    /// @return timeToMaturity Time-to-maturity in seconds.
    function _getTimeToMaturity() internal view returns (uint256) {
        uint256 maturityTime = hourglassDepositor.maturity();
        return maturityTime > block.timestamp ? maturityTime - block.timestamp : 0;
    }

    /// @notice Fetch the solvency ratio of the Hourglass system.
    /// @return solvencyRatio Solvency ratio of the Hourglass system (scaled by _base token decimals).
    function _getSolvencyRatio() internal view returns (uint256 solvencyRatio) {
        uint256 baseTokenScale = 10 ** baseTokenDecimals;
        uint256 underlyingTokenBalance = IERC20(underlyingToken).balanceOf(address(hourglassDepositor));
        uint256 ptSupply = IERC20(principalToken).totalSupply();
        uint256 ctSupply = IERC20(combinedToken).totalSupply();

        uint256 totalClaims = ptSupply + ctSupply;

        return (totalClaims > 0) ? (underlyingTokenBalance * baseTokenScale) / totalClaims : baseTokenScale;
    }
}
