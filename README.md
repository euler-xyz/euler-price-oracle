# Euler Oracles

## Table of Contents
<!-- TOC FOLLOWS -->
<!-- START OF TOC -->
<!-- md-toc: https://github.com/hoytech/md-toc -->

* [Table of Contents](#table-of-contents)
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
Euler Oracles conform to the shared `IEOracle` interface.
```solidity
error EOracle_NoAnswer();
error EOracle_NotSupported(address base, address quote);
error EOracle_Overflow();
error EOracle_TooStale(uint256 staleness, uint256 maxStaleness);

function description() external view returns (OracleDescription.Description memory description);
function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount);
function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256 bidOutAmount, uint256 askOutAmount);
```

## Specification
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).
### Definitions
- **Base:** The asset which is being priced. This is the numerator of the base/quote pair.
- **Quote:** The asset which is used as the unit of account. This is the denominator of the base/quote pair.
- **EOracle:** Contracts that implement the `IEOracle` interface. EOracles can be composed together as part of the Euler Oracles system.
EOracles do not necessarily interface with external providers. They may be used as utility layers for routing, aggregation, or shared governance.
- **Adapter:** An EOracle that directly connects to external contracts or systems that provide pricing. An adapter validates the data and processes it
to conform to the `IEOracle` interface. An adapter may connect to canonical oracle systems like Chainlink or query external DeFi contracts for exchange rates 
(Uniswap V3, wstETH contract). An exception to the rule is the `ConstantOracle` which returns a hard-coded exchange rate but is still regarded to be an adapter for consistency.
- **Strategy:** An EOracle that serves as an intermediary logic layer. Strategies forward calls to one or many child EOracles. An example strategy is a router for base/quote pairs or a median aggregator of multiple adapters.=
- **Resolution tree:** A tree data structure with EOracles as nodes. The resolution tree defines the complete oracle configuration for a given EVault. 
External calls will always enter via the root of the tree and follow nested call path down to a leaf. The value returned by the leaf will be propagated to the root and returned to the caller. 
Leaves of the resolution tree are adapters. Internal nodes are strategies. The tree branches out when it contains a strategy that connects to multiple child EOracles. 
The resolution tree only defines the topology of the oracle configuration. The path taken by a specific call may depend on the logic inside strategies.

### Methods
Oracles MUST implement `description`, `getQuote` and `getQuotes` as defined by the `IPriceOracle` interface and as specified in this specification.

#### `description`
```solidity
enum Variant {ADAPTER, STRATEGY}
enum Authority {GOVERNED, FINALIZED}
enum Upgradeability {UPGRADEABLE, IMMUTABLE}
enum Algorithm {SPOT, MEDIAN, ... , OTHER}
enum PaymentModel {FREE, SUBSCRIPTION, PER_REQUEST, OTHER}
enum RequestModel {PUSH, PULL, SIGNATURE, INTERNAL, OTHER}

struct Configuration {
    uint256 maxStaleness;
    address governor;
    bool supportsBidAskSpread;
}

struct Description {
    Algorithm algorithm;
    Authority authority;
    PaymentModel paymentModel;
    RequestModel requestModel;
    Variant variant;
    Configuration configuration;
    string name;
}
```
> Some definitions are redacted for brevity. See [src/lib/OracleDescription.sol](src/lib/OracleDescription.sol) for all definitions.
```solidity
function description() external view returns (Description memory);
```
- MUST NOT revert. 
- MUST faithfully represent the properties and configuration of the EOracle. 
- MUST reflect changes to the EOracle's properties as a result of governance or other mechanisms.
- `variant` MUST NOT change throughout the lifecycle of the EOracle.
- `authority` MUST reflect the current governance state of the EOracle as defined in the [Euler Vaults whitepaper.](https://github.com/euler-xyz/euler-vaults-docs/blob/master/whitepaper.md#governed-vs-finalised)
- `upgradeability` MUST reflect the deployment configuration in the EOracleFactory as defined in the [Euler Vaults whitepaper.](https://github.com/euler-xyz/euler-vaults-docs/blob/master/whitepaper.md#upgradeable-vs-immutable)
- `algorithm` MUST be the pricing algorithm implemented by the connected external oracle if the EOracle is an adapter.
- `algorithm` MUST be the aggregation algorithm internally implemented by the strategy if the EOracle is a strategy.
- `paymentModel` MUST reflect either the external oracle's payment model if the EOracle is an adapter.
- `paymentModel` MUST reflect the strategy's payment model if the EOracle is a strategy.
- `requestModel` MUST be `PUSH` if price updates are periodically updated on-chain without caller intent.
- `requestModel` MUST be `PULL` if the caller has to make a transaction to request an up-to-date price to be pushed on-chain at a later block.
- `requestModel` MUST be `SIGNATURE` if the price is provided as data signed off-chain by a trusted party.
- `requestModel` MUST be `INTERNAL` if the EOracle is a strategy or an adapter whose pricing logic is fully internalized.
- `Configuration.maxStaleness` MUST be the maximum age in seconds of the price accepted by the EOracle. A value of 0 means that the price is updated every block.
- `Configuration.governor` MUST be `address(0)` if `authority` is `FINALIZED` or else the governor address as defined in the [Euler Vaults whitepaper.](https://github.com/euler-xyz/euler-vaults-docs/blob/master/whitepaper.md#governed-vs-finalised)
- `Configuration.supportsBidAskSpread` MUST be `true` if the EOracle natively supports quotes with bid-ask spreads. If this is `false`, then `getQuotes(in,b,q)` MUST return `(getQuote(in,b,q), getQuote(in,b,q))`.
- An EOracle MAY use the enum member `OTHER` whenever none of the other members accurately describe its properties.
- `name` MUST NOT change throughout the lifecycle of the EOracle.
- `name` SHOULD be a short string that describes the EOracle. EOracles are free to choose the format.
- `name` is RECOMMENDED to include the common name of the external system that is queried (by adapters).

#### `getQuote`
1. MUST revert with the `PriceOracle_NotSupported` with
1. `getQuote` MUST revert with the appropriate error from `IPriceOracle` whenever possible. 

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
