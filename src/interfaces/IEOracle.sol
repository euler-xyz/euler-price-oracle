// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @title IEOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Common EOracle interface.
interface IEOracle {
    /// @notice Describes the properties of the oracle. Intended for off-chain use.
    /// @dev Integrators MUST NOT blindly trust the description as it can be easily spoofed.
    /// @dev Integrators SHOULD check the chain of trust in the official Euler Oracle Factory.
    function description() external view returns (OracleDescription.Description memory description);

    /// @notice One-sided price: How much quote token you would get for inAmount of base token, assuming no price spread
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token address or Denomination of the asset that is being priced.
    /// @param quote The token address or Denomination of the asset that is the unit of account.
    /// @return outAmount The amount of `quote` that is equivalent to `inAmount` of `base`.
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount);

    /// @notice Two-sided price: How much quote token you would get/spend for selling/buying inAmount of base token
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token address or Denomination of the asset that is being priced.
    /// @param quote The token address or Denomination of the asset that is the unit of account.
    /// @return bidOutAmount The amount of `quote` you would get for selling `inAmount` of `base`.
    /// @return askOutAmount The amount of `quote` you would get for buying `inAmount` of `base`.
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        returns (uint256 bidOutAmount, uint256 askOutAmount);
}
