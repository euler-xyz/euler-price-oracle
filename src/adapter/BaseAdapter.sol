// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {Errors} from "../lib/Errors.sol";

/// @title BaseAdapter
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Abstract adapter with virtual bid/ask pricing.
abstract contract BaseAdapter is IPriceOracle {
    // @dev Addresses <= 0x00..00ffffffff are considered to have 18 decimals without dispatching a call.
    // This avoids collisions between ISO 4217 representations and (future) precompiles.
    uint256 internal constant ADDRESS_RESERVED_RANGE = 0xffffffff;

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

    /// @notice Determine the decimals of an asset.
    /// @param asset ERC20 token address or other asset.
    /// @dev Oracles can use ERC-7535, ISO 4217 or other conventions to represent non-ERC20 assets as addresses.
    /// Integrator Note: `_getDecimals` will return 18 if `asset` is:
    /// - any address <= 0x00000000000000000000000000000000ffffffff (4294967295)
    /// - an EOA or a to-be-deployed contract (which may implement `decimals()` after deployment).
    /// - a contract that does not implement `decimals()`.
    /// @return The decimals of the asset.
    function _getDecimals(address asset) internal view returns (uint8) {
        if (uint160(asset) <= ADDRESS_RESERVED_RANGE) return 18;
        (bool success, bytes memory data) = asset.staticcall(abi.encodeCall(IERC20.decimals, ()));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Return the quote for the given price query.
    /// @dev Must be overridden in the inheriting contract.
    function _getQuote(uint256, address, address) internal view virtual returns (uint256);
}
