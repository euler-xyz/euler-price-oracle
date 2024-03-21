// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title BaseAdapter
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Abstract adapter with virtual bid/ask pricing.
abstract contract BaseAdapter is IPriceOracle {
    /// @inheritdoc IPriceOracle
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    /// @inheritdoc IPriceOracle
    /// @dev Does not support true bid/ask pricing.
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    /// @notice Get the decimals of the asset, falling back to 18 decimals for ISO 4217 currencies.
    /// @param token ERC20 token address or ISO 4217-encoded currency.
    /// @dev Rejects address(0), returns 18 for all three-digit addresses, calls decimals() on other addresses.
    /// @return The decimals of the asset.
    function _getDecimals(address token) internal view returns (uint8) {
        if (token == address(0)) revert Errors.PriceOracle_InvalidConfiguration();
        if (uint160(token) < 1000) return 18;
        (bool success, bytes memory data) = token.staticcall(abi.encodeCall(IERC20.decimals, ()));
        if (!success) revert Errors.PriceOracle_InvalidConfiguration();
        return abi.decode(data, (uint8));
    }

    function _getQuote(uint256, address, address) internal view virtual returns (uint256);
}
