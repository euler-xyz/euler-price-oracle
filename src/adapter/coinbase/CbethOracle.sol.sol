// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseAdapter} from "src/adapter/BaseAdapter.sol";
import {ICbETH} from "src/adapter/coinbase/ICbETH.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title CbethOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing Coinbase cbETH <-> ETH via the cbETH contract.
contract CbethOracle is BaseAdapter {
    /// @dev The address of Wrapped Ether.
    address public immutable weth;
    /// @dev The address of Coinbase cbETH.
    address public immutable cbeth;

    /// @notice Deploy a CbethOracle.
    /// @param _weth The address of Wrapped Ether.
    /// @param _cbeth The address of Coinbase cbETH.
    /// @dev The oracle will support cbETH/WETH and WETH/cbETH pricing.
    constructor(address _weth, address _cbeth) {
        weth = _weth;
        cbeth = _cbeth;
    }

    /// @notice Get a quote by querying the exchange rate from the cbETH contract.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced. Either cbETH or WETH.
    /// @param quote The token that is the unit of account. Either WETH or cbETH.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        uint256 rate = ICbETH(cbeth).exchangeRate();
        if (base == cbeth && quote == weth) {
            return inAmount * rate / 1e18;
        } else if (base == weth && quote == cbeth) {
            return inAmount * 1e18 / rate;
        }
        revert Errors.PriceOracle_NotSupported(base, quote);
    }
}
