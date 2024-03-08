// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC4626} from "@solady/tokens/ERC4626.sol";
import {BaseAdapter} from "src/adapter/BaseAdapter.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title ERC4626Oracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing ERC4626 share tokens. The prices returned by this adapter
/// may be manipulable. Check the implementation of the vault.
/// @dev Calls `convertToAssets` or `convertToShares` on the ERC4626 vault.
contract ERC4626Oracle is BaseAdapter {
    /// @notice The address of the ERC4626 vault.
    address public immutable vault;
    /// @notice The address of the vault's underlying token.
    address public immutable asset;

    /// @notice Deploy an ERC4626Oracle.
    /// @param _vault The address of the ERC4626 vault.
    /// @dev The oracle will support share/asset and asset/share pricing.
    constructor(address _vault) {
        vault = _vault;
        asset = ERC4626(_vault).asset();
    }

    /// @notice Get a quote by calling the corresponding `convert*` method on the ERC4626 vault.
    /// @dev Calls `convertToAssets` for share/asset and `convertToShares` for asset/share.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced. Either `vault` or `asset`.
    /// @param quote The token that is the unit of account. Either `asset` or `vault`.
    /// @return The converted amount by the vault.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        if (base == vault && quote == asset) {
            return ERC4626(vault).convertToAssets(inAmount);
        } else if (base == asset && quote == vault) {
            return ERC4626(vault).convertToShares(inAmount);
        }
        revert Errors.PriceOracle_NotSupported(base, quote);
    }
}
