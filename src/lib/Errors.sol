// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

library Errors {
    error AlreadyConfigured(address base, address quote);
    error Arity2Mismatch(uint256 arityA, uint256 arityB);
    error Arity3Mismatch(uint256 arityA, uint256 arityB, uint256 arityC);
    error InvalidAlgorithm();
    error NoAnswer();
    error NotSupported(address base, address quote);
    error PriceTooStale(uint256 staleness, uint256 maxStaleness);
    error QuorumNotReached(uint256 count, uint256 quorum);
    error QuorumTooLarge(uint256 quorum, uint256 maxQuorum);
    error QuorumZero();
    error ConfigExpired(address base, address quote);
    error InAmountTooLarge();
    error NoPoolConfigured(address base, address quote);

    error PoolMismatch(address configPool, address factoryPool);

    error ConfigDoesNotExist(address base, address quote);
    error CouldNotPrice();
    error InvalidPrice(uint256 price);

    error InvalidPythConfidenceInterval(int64 price, uint64 conf);
    error InvalidPythExponent(int32 expo);
    error InvalidPythPrice(int64 price);

    error CallReverted(bytes reason);
    error InvalidAnswer(int256 answer);
    error NoFeedConfigured(address base, address quote);
    error RoundIncomplete();
    error RoundTooLong(uint256 duration, uint256 maxDuration);

    error ChainlinkFeedNotEnabled(address feed);
    error CurvePoolNotFound(address lpToken);
    error UniV3PoolNotFound(address base, address quote);
}
