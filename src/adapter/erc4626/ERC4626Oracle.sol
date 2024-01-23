// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC4626} from "@solady/tokens/ERC4626.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing ERC4626 tokens.
/// @dev Prices may be manipulable. Check the implementation of the vault.
contract ERC4626Oracle is IEOracle {
    address public immutable vault;
    address public immutable asset;

    constructor(address _vault) {
        vault = _vault;
        asset = ERC4626(_vault).asset();
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.ERC4626Oracle();
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        if (base == vault && quote == asset) {
            return ERC4626(vault).convertToAssets(inAmount);
        } else if (base == asset && quote == vault) {
            return ERC4626(vault).convertToShares(inAmount);
        }
        revert Errors.EOracle_NotSupported(base, quote);
    }
}
