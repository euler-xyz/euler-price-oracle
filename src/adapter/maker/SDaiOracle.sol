// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC4626} from "forge-std/interfaces/IERC4626.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {BaseAdapter, Errors} from "src/adapter/BaseAdapter.sol";

/// @title SDaiOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing Maker sDAI <-> DAI.
contract SDaiOracle is BaseAdapter {
    /// @notice The address of the DAI token.
    address public immutable dai;
    /// @notice The address of the sDAI token.
    address public immutable sDai;

    /// @notice Deploy an SDaiOracle.
    /// @param _dai The address of the DAI token.
    /// @param _sDai The address of the sDAI token.
    /// @dev The oracle will support sDAI/DAI and DAI/sDAI pricing.
    constructor(address _dai, address _sDai) {
        dai = _dai;
        sDai = _sDai;
    }

    /// @notice Get a quote by querying the exchange rate from the DSR Pot contract.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced. Either `sDai` or `dai`.
    /// @param quote The token that is the unit of account. Either `dai` or `sDai`.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        if (base == sDai && quote == dai) {
            return IERC4626(sDai).convertToAssets(inAmount);
        } else if (base == dai && quote == sDai) {
            return IERC4626(sDai).convertToShares(inAmount);
        }
        revert Errors.PriceOracle_NotSupported(base, quote);
    }
}
