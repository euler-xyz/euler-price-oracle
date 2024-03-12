// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseAdapter} from "src/adapter/BaseAdapter.sol";
import {IMethStaking} from "src/adapter/mantle/IMethStaking.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title MethOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing Mantle mETH <-> ETH via the mETH staking contract.
contract MethOracle is BaseAdapter {
    /// @dev The address of Wrapped Ether.
    address public immutable weth;
    /// @dev The address of Mantle mETH.
    address public immutable meth;
    /// @dev The address of the Mantle mETH staking contract.
    address public immutable methStaking;

    /// @notice Deploy a MethOracle.
    /// @param _weth The address of Wrapped Ether.
    /// @param _meth The address of Mantle mETH.
    /// @param _methStaking The address of the Mantle mETH staking contract.
    /// @dev The oracle will support mETH/WETH and WETH/mETH pricing.
    constructor(address _weth, address _meth, address _methStaking) {
        weth = _weth;
        meth = _meth;
        methStaking = _methStaking;
    }

    /// @notice Get a quote by querying the exchange rate from the mETH staking contract.
    /// @dev Calls `mETHToETH` for mETH/WETH and `ethToMETH` for WETH/mETH.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced. Either mETH or WETH.
    /// @param quote The token that is the unit of account. Either WETH or mETH.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        if (base == meth && quote == weth) {
            return IMethStaking(meth).mETHToETH(inAmount);
        } else if (base == weth && quote == meth) {
            return IMethStaking(weth).ethToMETH(inAmount);
        }
        revert Errors.PriceOracle_NotSupported(base, quote);
    }
}
