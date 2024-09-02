// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {IStEth} from "./IStEth.sol";

/// @title LidoFundamentalOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing weth <-> wstEth via the Lido stEth contract.
/// @dev This is an exchange rate/fundamental oracle that assumes stEth and weth are 1:1.
contract LidoFundamentalOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "LidoFundamentalOracle";
    /// @notice The address of Lido staked Ether.
    /// @dev This address will not change.
    address public constant STETH = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    /// @notice The address of Lido wrapped staked Ether.
    /// @dev This address will not change.
    address public constant WSTETH = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    /// @notice The address of Wrapped Ether.
    /// @dev This address will not change.
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice Get a quote by querying the exchange rate from the stEth contract.
    /// @dev Calls `getSharesByPooledEth` for weth/wstEth and `getPooledEthByShares` for wstEth/weth.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced. Either `weth` or `wstEth`.
    /// @param quote The token that is the unit of account. Either `wstEth` or `weth`.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        if (base == WETH && quote == WSTETH) {
            return IStEth(STETH).getSharesByPooledEth(inAmount);
        } else if (base == WSTETH && quote == WETH) {
            return IStEth(STETH).getPooledEthByShares(inAmount);
        }
        revert Errors.PriceOracle_NotSupported(base, quote);
    }
}
