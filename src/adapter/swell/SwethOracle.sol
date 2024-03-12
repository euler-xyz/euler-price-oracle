// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseAdapter} from "src/adapter/BaseAdapter.sol";
import {ISwETH} from "src/adapter/swell/ISwETH.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title SwethOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing Swell swETH <-> ETH via the swETH contract.
contract SwethOracle is BaseAdapter {
    /// @dev The address of Wrapped Etherr.
    address public immutable weth;
    /// @dev The address of Swell Ether.
    address public immutable sweth;

    /// @notice Deploy a SwethOracle.
    /// @param _weth The address of Wrapped Ether.
    /// @param _sweth The address of Swell Ether.
    /// @dev The oracle will support swETH/WETH and WETH/swETH pricing.
    constructor(address _weth, address _sweth) {
        weth = _weth;
        sweth = _sweth;
    }

    /// @notice Get a quote by querying the exchange rate from the swETH staking contract.
    /// @dev Calls `swETHToETHRate` for swETH/WETH and `ethToSwETHRate` for WETH/swETH.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced. Either swETH or WETH.
    /// @param quote The token that is the unit of account. Either WETH or swETH.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        if (base == sweth && quote == weth) {
            return inAmount * ISwETH(sweth).swETHToETHRate() / 1e18;
        } else if (base == weth && quote == sweth) {
            return inAmount * ISwETH(sweth).ethToSwETHRate() / 1e18;
        }
        revert Errors.PriceOracle_NotSupported(base, quote);
    }
}
