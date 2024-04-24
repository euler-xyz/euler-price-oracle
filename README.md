# Euler Price Oracles

Euler Price Oracles is a library of oracle integrations and useful primitives to combine them. Components of the library encapsulate the logic for querying, validating, and converting, and expose it to consumers in a fluent quoting [interface.](#ipriceoracle) 

To understand how Price Oracles fit into the [Euler Vault Kit,](https://github.com/euler-xyz/euler-vault-kit) refer to the relevant section of the [EVK whitepaper.](https://docs.euler.finance/euler-vault-kit-white-paper/#price-oracles)

To explore, build and integrate Euler Price Oracles, refer to [Development](#development).

## `IPriceOracle`

[Source: IPriceOracle.sol](src/interfaces/IPriceOracle.sol)

Components of the library implement an opinionated quoting interface.
```solidity
/// @return outAmount The amount of `quote` that is equivalent to `inAmount` of `base`.
function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount);

/// @return bidOutAmount The amount of `quote` you would get for selling `inAmount` of `base`.
/// @return askOutAmount The amount of `quote` you would spend for buying `inAmount` of `base`.
function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256 bidOutAmount, uint256 askOutAmount);
```

`IPriceOracle` makes two innovations in how it shapes oracle interactions that make oracle integrations in DeFi safer.

### Quoting Prices

Euler Price Oracles are unique in that they expose a flexible quoting interface instead of reporting the unit price like most oracles.

To illustrate the differences imagine a Chainlink price feed which reports the value `1 EUL/ETH`, the *unit price* of `EUL`. Now consider an `IPriceOracle` adapter for the feed. In `getQuote` it fetches the unit price, multiplies it by `inAmount`, and returns the quantity `inAmount EUL/ETH`. We call this a *quote* as it functionally resembles a DEX.

The quoting interface offers several benefits to consumers:
- **More intuitive queries:** Oracles are commonly used in DeFi to determine the value of assets. `IPriceOracle` does that out of the box.
- **More expressive interface:** The unit price is a special case of a quotation where `inAmount` is one whole unit of `base`.
- **Safe and flexible integrations:** Under `IPriceOracle` adapters are responsible for converting decimals internally. This allows consumers to more easily switch pricing sources as they can remain agnostic to the internals of a particular oracle provider.

### Bid/Ask Pricing

Euler Price Oracles additionally expose `getQuotes`, a method that returns two prices: the selling price (bid) and the buying price (ask). 

While few oracles support bid/ask pricing currently, we anticipate its wider adoption in DeFi markets as on-chain liquidity matures and market structure approximates that of financial markets. Bid/ask prices are inherently safer to use in lending markets as they accurately reflect price spreads and slippage.  

The `getQuotes` interface is also important as it allows for custom pricing strategies to be built under the `IPriceOracle` interfaces. Examples include:
 - Querying two oracles and returning the lower and higher quotes.
 - Reporting two quotes from a single source e.g. a TWAP and a [median.](https://github.com/euler-xyz/median-oracle)
 - Applying a virtual spread or a confidence interval around a mid-price.

## Oracle Adapters
An adapter is a minimal, fully immutable contract that queries an external price feed. It is the atomic building block of the Euler Price Oracles library.

### Design Principles

The `IPriceOracle` interface is permissive in that it does not prescribe a particular way to implement it. However the adapters in this library are implemented according to a strict set of **design principles** that we believe are crucial for a safe, open, and self-governed future.


#### Immutable
Adapters are fully immutable code. They are neither upgradeable nor governable.

#### Minimally Responsible
An adapter connects to one pricing system and queries a single price feed in that system.

#### Bidirectional
An adapter works in both directions. If it supports quoting `X/Y` it must also support `Y/X`.

#### Observable
An adapter's parameters and acceptance logic are easily observed on-chain.

### Summary of Adapters
| Adapter       | Type      | Subtype | Pairs         | Parameters        |
| ------------- | --------- | ------  | ------------- | -------------------------------------------- |
| Chainlink     | External  | Push    | Vendor feeds  | feed, max staleness                          | 
| Chronicle     | External  | Push    | Vendor feeds  | feed, max staleness                          | 
| Pyth          | External  | Pull    | Vendor feeds  | feed, max staleness, max confidence interval |
| Redstone      | External  | Pull    | Vendor feeds  | feed, max staleness, cache ttl               |
| Lido          | On-chain  | Rate    | wstEth, stEth | -                                            |
| sDai          | On-chain  | Rate    | sDai, Dai     | -                                            |
| Uniswap V3    | On-chain  | TWAP    | UniV3 pools   | fee, twap window                             |


## Development

### Install
To install Price Oracles in a [Foundry](https://github.com/foundry-rs/foundry) project:

```sh
forge install euler-xyz/euler-price-oracle
```

### Development
Clone the repo:
```sh
git clone https://github.com/euler-xyz/euler-price-oracle.git && cd euler-price-oracle
```

### Testing
There are Ethereum fork tests under `test/fork`. To run fork tests set the `ETHEREUM_RPC_URL` variable in your environment:
```sh
# File: .env
ETHEREUM_RPC_URL=...
```

To omit fork tests:
```sh
forge test --no-match-contract Fork
```
## Adapters
An adapter is a contract that queries an external price feed and converts it into the `IPriceOracle` interface.

### Design Principles
While there are many ways to build adapters, the official adapters conform to a strict ruleset that enhance their security and composability.

#### Minimally Responsible
An adapter connects to one pricing system and queries a single price feed in that system.

#### Bidirectional
An adapter works in both directions. In other words, if it supports `getQuote/s(-, X, Y)` then it must support `getQuote/s(-, Y, X)`.

#### Immutable
Adapters are neither upgradeable nor governable. 

#### WYSIWYG
Parameters and acceptance criteria are easily observed on-chain.

### Summary of Adapters
| Adapter       | Source    | Tokens        | Parameters        |
| ------------- | --------- | ------        | ---------         |
| Chainlink     | External  | Any           | feed, staleness   | 
| Lido          | On-chain  | stEth, wstEth | -                 |
| sDAI          | On-chain  | sDAI, DAI     | -                 |
| Pyth          | External  | Any           | feed, staleness   |
| Redstone      | External  | Any           | feed, staleness   |
| Uniswap V3    | On-chain  | Any           | fee, twap window  |

### Security Questions
1. Adapters check whether the raw price data is valid or indicates an error condition (e.g. negative price or invalid signature). Are all cases caught?

1. Is the validation of the `PythStructs.Price` in the Pyth adapter correct? Should the `expo` boundary be increased or decreased?

1. Are there real-world cases where we would need a scaling factor larger than 10^38 in `ScaleUtils`? Interested in examples for Pyth, Redstone and Chainlink feeds. Note that we consider pricing "by analogy" a valid use case, i.e. using a ETH/USD feed for pricing WETH/GUSD.

1. Are there quirky feeds in Pyth, Redstone and Chainlink which break the assumptions of the adapters? For example, the Redstone adapter has `FEED_DECIMALS=8` hardcoded as a constant, whereas the Chainlink adapter relies that the aggregator decimals correctly correspond to the actual decimals.

1. Are there timing games / OEV opportunities that arise from the price caching logic in Redstone and Pyth adapters?

1. Are the on-chain exchange rate oracles (sDAI, stEth) immune to manipulation? Are there additional conditions that we can check which could signal that these rates cannot be trusted? 

1. Could any of the hardcoded addresses change under normal operation conditions e.g. as part of an upgrade?

## Safety
This software is **experimental** and is provided "as is" and "as available".

**No warranties are provided** and **no liability will be accepted for any loss** incurred through the use of this codebase.

Always include thorough tests when using Price Oracles to ensure it interacts correctly with your code.

Price Oracles is currently undergoing security audits and should not be used in production.

## License
(c) 2024 Euler Labs Ltd.

The Euler Price Oracles code is licensed under the [GPL-2.0-or-later](LICENSE) license.