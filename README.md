# Price Oracles
Price Oracles are the components of the Euler Vault Kit (EVK) that facilitate communication with external pricing systems and standardize their answers to a common interface. To read more about how Price Oracles fit in the context of Euler Vaults, refer to the [EVK whitepaper.](https://docs.euler.finance/euler-vault-kit-white-paper/#price-oracles)

## Install
To install Price Oracles in a [Foundry](https://github.com/foundry-rs/foundry) project:

```sh
forge install euler-xyz/euler-price-oracle
```

## Development
Clone the repo:
```sh
git clone https://github.com/euler-xyz/euler-price-oracle.git && cd euler-price-oracle
```

## Testing
There are Ethereum fork tests under `test/fork`. To run fork tests set the `ETHEREUM_RPC_URL` variable in your environment:
```sh
# File: .env
ETHEREUM_RPC_URL=...
```

To run tests:
```sh
forge test
```

To omit fork tests:
```sh
forge test --no-match-contract Fork
```


## `IPriceOracle`
[Source: IPriceOracle.sol](src/interfaces/IPriceOracle.sol)

The standard interface exposes two pricing functions: 
```solidity
/// @return outAmount The amount of `quote` that is equivalent to `inAmount` of `base`.
function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount);

/// @return bidOutAmount The amount of `quote` you would get for selling `inAmount` of `base`.
/// @return askOutAmount The amount of `quote` you would get for buying `inAmount` of `base`.
function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256 bidOutAmount, uint256 askOutAmount);
```

While most oracle systems report unit prices, Price Oracles report *quotes*. This means that conversion and rounding is the responsibility of Price Oracles, whereas consumers can treat the returned `outAmount` like a DEX quote.

Price Oracles also expose a pricing function that returns bid/ask quotes. Although few oracle systems support them directly, the bid/ask interface opens the door for custom pricing strategies like aggregating multiple sources, applying a virtual spread or a confidence interval.

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
| Rocketpool    | On-chain  | rETH, WETH    | -                 |
| Uniswap V3    | On-chain  | Any           | fee, twap window  |

### Security Questions
1. Adapters check whether the raw price data is valid or indicates an error condition (e.g. negative price or invalid signature). Are all cases caught?

1. Is the validation of the `PythStructs.Price` in the Pyth adapter correct? Should the `expo` boundary be increased or decreased?

1. Are there real-world cases where we would need a scaling factor larger than 10^38 in `ScaleUtils`? Interested in examples for Pyth, Redstone and Chainlink feeds. Note that we consider pricing "by analogy" a valid use case, i.e. using a ETH/USD feed for pricing WETH/GUSD.

1. Are there quirky feeds in Pyth, Redstone and Chainlink which break the assumptions of the adapters? For example, the Redstone adapter has `FEED_DECIMALS=8` hardcoded as a constant, whereas the Chainlink adapter relies that the aggregator decimals correctly correspond to the actual decimals.

1. Are there timing games / OEV opportunities that arise from the price caching logic in Redstone and Pyth adapters?

1. Are the on-chain exchange rate oracles (sDAI, rETH, stEth) immune to manipulation? Are there additional conditions that we can check which could signal that these rates cannot be trusted? 

1. Could any of the hardcoded addresses change under normal operation conditions e.g. as part of an upgrade?

## Safety
This software is **experimental** and is provided "as is" and "as available".

**No warranties are provided** and **no liability will be accepted for any loss** incurred through the use of this codebase.

Always include thorough tests when using Price Oracles to ensure it interacts correctly with your code.

Price Oracles is currently undergoing security audits and should not be used in production.

## License
Licensed under the [GPL-2.0-or-later](LICENSE) license.