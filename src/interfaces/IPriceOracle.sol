// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {OracleDescription} from "src/lib/OracleDescription.sol";

interface IPriceOracle {
    /// @notice Describes the oracle. Intended for off-chain introspection.
    /// @dev Integrators MUST NOT blindly trust the description as it can be easily spoofed.
    /// @dev Integrators SHOULD check the chain of trust in the  official Euler Oracle Factory.
    function description() external view returns (OracleDescription.Description memory description);
    /// @notice One-sided price: How much quote token you would get for inAmount of base token, assuming no price spread
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount);
    /// @notice Two-sided price: How much quote token you would get/spend for selling/buying inAmount of base token
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        returns (uint256 bidOutAmount, uint256 askOutAmount);
}
