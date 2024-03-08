// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

/// @title Errors
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Collects common errors in EOracles.
library Errors {
    /// @notice Chainlink feed returned an invalid answer.
    /// @param answer The "answer" parameter in the round data tuple.
    /// @dev Thrown when answer <= 0.
    error Chainlink_InvalidAnswer(int256 answer);
    /// @notice The base/quote path is not supported.
    /// @param base The address of the base asset.
    /// @param quote The address of the quote asset.
    error EOracle_NotSupported(address base, address quote);
    /// @notice The quote cannot be completed due to overflow.
    error EOracle_Overflow();
    /// @notice The price is too stale.
    /// @param staleness The time elapsed since the price was updated.
    /// @param maxStaleness The maximum time elapsed since the last price update.
    error EOracle_TooStale(uint256 staleness, uint256 maxStaleness);
    /// @notice The contract was already initialized.
    error Governance_AlreadyInitialized();
    /// @notice The method can only be called by the governor.
    error Governance_CallerNotGovernor();
    /// @notice Pyth returned an out-of-range value for the confidence interval.
    /// @param price The "price" parameter in the price struct.
    /// @param conf The "price" parameter in the price struct.
    error Pyth_InvalidConfidenceInterval(int64 price, uint64 conf);
    /// @notice Pyth returned an out-of-range value for the exponent.
    /// @param expo The "expo" parameter in the price struct.
    error Pyth_InvalidExponent(int32 expo);
    /// @notice Pyth returned an out-of-range value for the price.
    /// @param price The "price" parameter in the price struct.
    error Pyth_InvalidPrice(int64 price);
    /// @notice The length of the TWAP window is too small or too large.
    error UniswapV3_InvalidTwapWindow();
    /// @notice Wrapped UniswapV3 error
    error UniswapV3_ObserveError(bytes data);
}
