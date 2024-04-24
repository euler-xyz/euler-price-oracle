# Euler Price Oracles

Euler Price Oracles is a library of minimal and immutable oracle adapters. Contracts in this library follow [IPriceOracle,](https://github.com/euler-xyz/IPriceOracle) an opinionated quote-based interface for on-chain pricing. To understand how Price Oracles fit into the [Euler Vault Kit,](https://github.com/euler-xyz/euler-vault-kit) read the [EVK whitepaper.](https://docs.euler.finance/euler-vault-kit-white-paper/#price-oracles)

## `IPriceOracle`

All contracts in this library implement the [IPriceOracle](https://github.com/euler-xyz/IPriceOracle) interface.
```solidity
/// @return outAmount The amount of `quote` that is equivalent to `inAmount` of `base`.
function getQuote(
    uint256 inAmount, 
    address base, 
    address quote
) external view returns (uint256 outAmount);

/// @return bidOutAmount The amount of `quote` you would get for selling `inAmount` of `base`.
/// @return askOutAmount The amount of `quote` you would spend for buying `inAmount` of `base`.
function getQuotes(
    uint256 inAmount, 
    address base, 
    address quote
) external view returns (uint256 bidOutAmount, uint256 askOutAmount);
```

This interface shapes oracle interactions in an important way: it forces the consumer to think in [amounts rather than prices.](https://hackernoon.com/getting-prices-right)

### Quotes

Euler Price Oracles are unique in that they expose a flexible quoting interface instead of reporting a static price.

> Imagine a Chainlink price feed which reports the value `1 EUL/ETH`, the *unit price* of `EUL`. Now consider an `IPriceOracle` adapter for the feed. It will fetch the unit price, multiply it by `inAmount`, and return the quantity `inAmount EUL/ETH`. We call this a *quote* as it functionally resembles a swap on a decentralized exchange.

The quoting interface offers several benefits to consumers:
- **More intuitive queries:** Oracles are commonly used in DeFi to determine the value of assets. `getQuote` does exactly that.
- **More expressive interface:** The unit price is a special case of a quote where `inAmount` is one whole unit of `base`.
- **Safe and flexible integrations:** Under `IPriceOracle` adapters are internally responsible for converting decimals. This allows consumers to decouple themselves from a particular provider as they can remain agnostic to its implementation details.

### Bid/Ask Pricing

Euler Price Oracles additionally expose `getQuotes` which returns two prices: the selling price (bid) and the buying price (ask). 

Bid/ask prices are inherently safer to use in lending markets as they can accurately reflect instantaneous price spreads. While few oracles support bid/ask prices currently, we anticipate their wider adoption in DeFi as on-chain liquidity matures. 

Importantly `getQuotes` allows for custom pricing strategies to be built under the `IPriceOracle` interface:
 - Querying two oracles and returning the lower and higher prices.
 - Reporting two prices from a single source e.g. a TWAP and a [median.](https://github.com/euler-xyz/median-oracle)
 - Applying a synthetic spread or a volatility-dependent confidence interval around a mid-price.

## Oracle Adapters

An adapter is a minimal, fully immutable contract that queries an external price feed. It is the atomic building block of the Euler Price Oracles library.

### Design Principles

The `IPriceOracle` interface is permissive in that it does not prescribe a particular way to implement it. However the adapters in this library adhere to a strict set of rules that we believe are necessary to enable safe, open, and self-governed markets to flourish.

#### Immutable

Adapters are fully immutable without governance or upgradeability.

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

## Safety

This software is **experimental** and is provided "as is" and "as available".

**No warranties are provided** and **no liability will be accepted for any loss** incurred through the use of this codebase.

Always include thorough tests when using Euler Price Oracles to ensure it interacts correctly with your code.

Euler Price Oracles is currently undergoing security audits and should not be used in production.

## License

(c) 2024 Euler Labs Ltd.

The Euler Price Oracles code is licensed under the [GPL-2.0-or-later](LICENSE) license.