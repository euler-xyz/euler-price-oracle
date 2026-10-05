// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC4626} from "forge-std/interfaces/IERC4626.sol";
import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";

/// @title ERC4626Oracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice PriceOracle adapter for ERC4626 vaults.
/// @dev Warning: This adapter may not be suitable for all ERC4626 vaults.
/// By ERC4626 spec `convert*` ignores liquidity restrictions, fees, slippage and per-user restrictions.
/// Therefore the reported price may not be realizable through `redeem` or `withdraw`.
/// @dev Warning: Exercise caution when using this pricing method for borrowable vaults.
/// Ensure that the price cannot be atomically manipulated by a donation attack.
contract ERC4626Oracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "ERC4626Oracle";
    /// @notice The address of the vault.
    address public immutable base;
    /// @notice The address of the vault's underlying asset.
    address public immutable quote;

    /// @notice Deploy an ERC4626Oracle.
    /// @param _vault The address of the ERC4626 vault to price.
    constructor(address _vault) {
        base = _vault;
        quote = IERC4626(_vault).asset();
    }

    /// @notice Get the quote from the ERC4626 vault.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the ERC4626 vault.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        if (_base == base && _quote == quote) {
            return IERC4626(base).convertToAssets(inAmount);
        } else if (_base == quote && _quote == base) {
            return IERC4626(base).convertToShares(inAmount);
        }

        revert Errors.PriceOracle_NotSupported(_base, _quote);
    }
}
