// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseAdapter} from "src/adapter/BaseAdapter.sol";
import {IWBETH} from "src/adapter/binance/IWBETH.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title WBETHOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing Binance wBETH <-> ETH via the wBETH contract.
contract WBETHOracle is BaseAdapter {
    /// @dev The address of Wrapped Ether.
    address public immutable weth;
    /// @dev The address of Binance wBETH.
    address public immutable wbeth;

    /// @notice Deploy a MethOracle.
    /// @param _weth The address of Wrapped Ether.
    /// @param _wbeth The address of Binance wBETH.
    /// @dev The oracle will support mETH/WETH and WETH/mETH pricing.
    constructor(address _weth, address _wbeth) {
        weth = _weth;
        wbeth = _wbeth;
    }

    /// @notice Get a quote by querying the exchange rate from the wBETH contract.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced. Either wBETH or WETH.
    /// @param quote The token that is the unit of account. Either WETH or wBETH.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        uint256 rate = IWBETH(wbeth).exchangeRate();
        if (base == wbeth && quote == weth) {
            return inAmount * rate / 1e18;
        } else if (base == weth && quote == wbeth) {
            return inAmount * 1e18 / rate;
        }
        revert Errors.PriceOracle_NotSupported(base, quote);
    }
}
