// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

/// @title Errors
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Collects common errors in EOracles.
library Errors {
    error Chainlink_InvalidAnswer(int256 answer);
    error EOracle_NotSupported(address base, address quote);
    error EOracle_Overflow();
    error EOracle_TooStale(uint256 staleness, uint256 maxStaleness);
    error Governance_AlreadyInitialized();
    error Governance_CallerNotGovernor();
    error Pyth_InvalidConfidenceInterval(int64 price, uint64 conf);
    error Pyth_InvalidExponent(int32 expo);
    error Pyth_InvalidPrice(int64 price);
    error UniswapV3_TwapWindowTooLong(uint32 twapWindow, uint32 maxTwapWindow);
}
