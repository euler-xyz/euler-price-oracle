// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

/// @author totomanov
/// @notice Stores common errors in Oracles.
/// @dev Collected here to reduce clutter in oracle contracts.
library Errors {
    error Aggregator_InvalidAlgorithm();
    error Aggregator_QuorumNotReached(uint256 count, uint256 quorum);
    error Aggregator_QuorumTooLarge(uint256 quorum, uint256 maxQuorum);
    error Aggregator_QuorumZero();
    error Arity2Mismatch(uint256 arityA, uint256 arityB);
    error Arity3Mismatch(uint256 arityA, uint256 arityB, uint256 arityC);
    error Chainlink_CallReverted(bytes reason);
    error Chainlink_FeedNotEnabled(address feed);
    error Chainlink_InvalidAnswer(int256 answer);
    error Chainlink_RoundIncomplete();
    error Chainlink_RoundTooLong(uint256 duration, uint256 maxDuration);
    error ConfigDoesNotExist(address base, address quote);
    error ConfigExists(address base, address quote);
    error ConfigExpired(address base, address quote);
    error Curve_PoolNotFound(address lpToken);
    error PriceOracle_NoAnswer();
    error PriceOracle_NotSupported(address base, address quote);
    error PriceOracle_Overflow();
    error PriceOracle_TooStale(uint256 staleness, uint256 maxStaleness);
    error Pyth_InvalidConfidenceInterval(int64 price, uint64 conf);
    error Pyth_InvalidExponent(int32 expo);
    error Pyth_InvalidPrice(int64 price);
    error Router_MalformedPairs(uint256 length);
    error Tellor_InvalidPrice(uint256 price);
    error UniswapV3_PoolMismatch(address configPool, address factoryPool);
    error UniswapV3_RoundTooLong(address base, address quote);
}
