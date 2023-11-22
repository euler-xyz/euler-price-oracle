# Euler Oracles

<!-- TOC FOLLOWS -->
<!-- START OF TOC -->
<!-- md-toc: https://github.com/hoytech/md-toc -->

* [Introduction](#introduction)
* [Interface](#interface)
* [Data structures](#data-structures)
    * [Immutable Address Array](#immutable-address-array)
    * [Packed uint32 Array](#packed-uint32-array)
* [Adapters](#adapters)
    * [Chainlink](#chainlink)
    * [Chronicle](#chronicle)
    * [Compound V2](#compound-v2)
    * [Constant](#constant)
    * [Curve](#curve)
    * [Lido](#lido)
    * [Pyth](#pyth)
    * [RocketPool](#rocketpool)
    * [Tellor](#tellor)
    * [Uniswap V3](#uniswap-v3)
    * [Yearn V2](#yearn-v2)
* [Strategies](#strategies)
    * [Aggregators](#aggregators)
        * [Supported Aggregator Algorithms](#supported-aggregator-algorithms)
        * [Custom Aggregator Algorithms](#custom-aggregator-algorithms)
    * [Linear](#linear)
        * [Supported Linear Algorithms](#supported-linear-algorithms)
    * [Routers](#routers)
        * [Supported Router Algorithms](#supported-router-algorithms)

<!-- END OF TOC -->

## Introduction

## Interface
Euler Oracles conform to the shared `IPriceOracle` interface.

## Data structures
There are two custom data structures that are useful for gas-efficient oracle components. Under `src/lib`.

### Immutable Address Array
An abstract contract that implements an in-code array of up to 8 addresses. It is constructed by passing in an in-memory address array. It internally records the cardinality of the array to perform bounds checking. It exposes a single internal function `_get(uint256 i)` to retrieve the `i`th element of the array.

Useful for immutable contracts with a small set of lookup addresses. Used in oracle strategies. This data structure inflates the deployment cost but reduces the usage cost because it saves on `SLOAD` operation for every query.

### Packed uint32 Array
A type library that packs 8 `uint32` types in a single 32-byte value. Useful for working with timestamps as well as bit masks for the immutable address array.

Used in aggregator strategies as a bitmask for the immutable address array. Also used in the linear strategies for storing the backoff timestamps.

## Adapters
Adapters connect to external oracles and adapt their interfaces and answers to the `IPriceOracle` interface.

### Chainlink
Queries a Chainlink oracle.

### Chronicle
Queries a Chronicle oracle.

### Compound V2
Queries a Compound V2 market to price a cToken in terms of its underlying.

### Constant
Returns a fixed exchange rate between two assets.

### Curve
Queries a Curve pool contract to price an LP token in terms of its underlying tokens.

### Lido
Queries the wstEth contract to convert between stEth and wstEth.

### Pyth
Queries a Pyth oracle. Supports bid-ask spread.

### RocketPool
Queries the Reth contract to convert between Reth and Eth.

### Tellor
Queries a Tellor oracle.

### Uniswap V3
Calculates the TWAP price maintained by a Uniswap V3 pool.

### Yearn V2
Queries a Yearn V2 vault contract to price a yvToken in terms of its underlying.

## Strategies
Euler Oracles support a library of common strategies.

### Aggregators
Aggregator strategies simultaneously query up to 8 underlying oracles and apply a statistical algorithm on the set of results. They also have a notion of `quorum`. Underlying oracles are queried with a `try-catch` mechanism and 

#### Supported Aggregator Algorithms
- `Min` returns the smallest quote of its underlying oracles.
- `Max` returns the largest quote of its underlying oracles.
- `Mean` returns the arithmentic mean quote of its underlying oracles.
- `Median` returns the statistical median quote of its underlying oracles. Note that if the cardinality of the set of answers received is even, then the median is the arithmetic mean of its middle 2 elements.
- `Weighted` returns the weighted arithmetic mean of the set of quotes. Weights are assigned at construction and immutable. If an underlying oracle does not produce a quote then its weight is dropped from the calculation.

#### Custom Aggregator Algorithms
To implement a custom algorithm extend the base `Aggregator` contract and override the virtual `_aggregateQuotes` function.
```solidity
function _aggregateQuotes(
    uint256[] memory quotes, 
    PackedUint32Array mask
) internal view returns (uint256) {
    /// custom aggregation logic
}
```

`quotes` is a compressed array of all valid quotes. `mask` is a bitmask-like data structure that indicates which of the underlying oracles returned successfully.

### Linear
Linear strategies maintain an ordered set of underlying oracles. Underlying oracles are queried in the given order until a valid quote is obtained.

#### Supported Linear Algorithms
- `LinearStrategy` implements the base logic outlined above.
- `ConstantBackoffLinearStrategy` extends the base algorithm and applies a constant-time backoff to unsuccessful queries. When an underlying oracle fails, it will be skipped for the next time period (e.g. 1 hour).

### Routers
Router strategies implement traffic control algorithms. Routers are most useful as top-level entry points for the underlying oracle resolution tree.

#### Supported Router Algorithms
- `SimpleRouter` supports an on-chain mapping of `(base,quote) -> oracle`.
- `FallbackRouter` extends `SimpleRouter` with a fallback oracle that is queried for all unresolved paths.
