---
title: Euler Price Oracles
description: A composable on-chain pricing system
---

# Euler Price Oracles

Anton Totomanov, Dariusz Glowinski, Kasper Pawlowski, Michael Bentley, Doug Hoyte

## Introduction

The Euler Price Oracle system is a composable on-chain pricing system. It is built around an interface called `IPriceOracle`, which is an abstraction for querying a diverse range of external pricing oracles and normalising their answers.

A contract that implements `IPriceOracle` is called a *provider* and can be queried to retrieve the price of one or more pairs of assets. Internally, providers can resolve pricing requests in any way they like. Of course, providers should refrain from using price feeds that can be manipulated by attackers.

`IPriceOracle` is intended to be future-proof. Price consumers can transparently be switched to use new types of oracles as they become available, including [pull-based](#pull-based) oracles, [time-weighted median](https://github.com/euler-xyz/median-oracle) oracles, and others.

In our modular reference implementation, external pricing oracles are integrated into the system with *adapters*. Adapters are immutable and ungoverned smart contracts that expose the `IPriceOracle` interface, invoke external oracles, and then convert and return the results.

We also implement a contract called `EulerRouter`. Just like the adapters, router instances expose the `IPriceOracle` interface. However, their function is to delegate pricing operations to other `IPriceOracle` providers (adapters, other routers, etc). Routers are immutable, but may optionally be governed, which allows the governor to change which providers are queried.

## `IPriceOracle`

    interface IPriceOracle {
        /// @return General description of this oracle implementation
        function name() external view returns (string memory);

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
    }

## Currencies

In foreign exchange terminology, prices are specified for pairs of currencies called *base* and *quote*, like this: `BASE/QUOTE`. The price represents the amount of the quote currency with the same value as 1 unit of the base currency. For example, if the price for `EUR/USD` is 1.1, then 1.1 USD is worth 1 EUR.

At the `IPriceOracle` level, currencies are referred to by ERC-20 token addresses. `IPriceOracle` requires that token addresses for both `base` and `quote` are provided for each query. This makes it unambiguous what the returned values represent, and allows an implementation to support quoting in multiple currencies.

Instead of token addresses, users can request prices based on fiat currencies or precious metals by casting numeric [ISO 4217](https://en.wikipedia.org/wiki/ISO_4217) currency codes into addresses. For example, USD has the ISO code of 840, so `address(840)` which corresponds to `0x0000000000000000000000000000000000000348` can be used instead. Values denominated in these special fiat addresses are defined to have 18 decimals.

### Quotes

Instead of returning price fractions, `IPriceOracle` accepts an `inAmount` parameter and returns the amount of `quote` that this could hypothetically be exchanged for. This has several advantages:

* More intuitive queries: Oracles are commonly used in DeFi to determine the value of some quantity of assets, and this interface supports that directly.
* More expressive interface: The unit price is a special case of a quote where inAmount is one whole unit of `base`.
* Abstracts away differences in decimals: Because providers are internally responsible for managing the fixed point precisions, consumers have fewer opportunities to make decimal-related mistakes.
* Reduces the impact of precision loss: In some extreme cases, forcing rounding in order to represent a unit price can introduce unnecessary precision loss (see the [Precision Loss Example appendix](#precision-loss-example)).

For a more comprehensive argument in favour of quote-based pricing, see [Getting Prices Right](https://hackernoon.com/getting-prices-right).

Note that a return value of `0` is allowed, and is not considered an error. This can happen either because the price is so low that `inAmount` is considered worthless, or because `inAmount` was so low that the output amount rounds to `0`, or both. True error conditions should be signalled by reverting.

### Spreads

For prices to make sense logically, there needs to be two values: a bid (what you could sell for) and an ask (what you could buy for). The bid must always be lower than the ask. Otherwise, trading activity would occur until a [market clearing](https://en.wikipedia.org/wiki/Market_clearing) condition was reached, leaving a non-zero gap between the bid and ask. More generally, the simplified notion of their being a categorically correct price for an asset at all [is mistaken](https://medium.com/eulerfinance/prices-and-oracles-2da0126a138).

The `getQuotes` function supports returning separate bid and ask values. The difference between them is called the *spread*. Conceptually, the spread can be considered a confidence interval: The oracle is reporting that the current fair market value lies somewhere within this range.

The meaning of the spread is provider-specific. Providers that are unaware of pricing uncertainty can simply use a spread of 0 (where bid is equal to ask). Some oracles may themselves provide bid/ask prices or confidence estimates, and providers can propagate these to price consumers. [Aggregate](#experimental-components) components may query multiple pricing sources and infer pricing uncertainty from their differences. Providers may also take into account `inAmount` when computing a spread: Typically, the larger a trade, the worse the average execution price will be ("size-aware pricing").

In the context of spreads, the result returned by `getQuote` is called the *mid-point*. This is somewhat of a misnomer since providers are not required to ensure the mid-point is exactly half-way between the bid and ask. Providers must only ensure that the following holds at any given time:

    bid <= mid-point <= ask

Similar to spreads themselves, the meaning of the mid-point is provider-specific. Conceptually, it should represent the provider's best guess as to where inside the spread the fair market value is most likely to be. If no relevant information is available, then a provider may choose the half-way point as the mid-point by averaging the bid and ask. Note that when averaging price fractions, a geometric mean is more appropriate than an arithmetic mean (ie, the mid-point of 0.5 and 2 should be 1, not 1.25).

When returning non-zero spreads, the price oracle must ensure that amounts are rounded away from the mid-point. In other words, bid amounts are to be rounded down, and ask amounts rounded up. This pessimises the value that would be received through a conversion, widening the spread and increasing the price uncertainty.

See the [Lending Application appendix](#lending-application) for how spreads can be employed in lending applications.

### Oracle Parameters

Often, price oracles will expose parameters to the caller such as maximum allowed price staleness, TWAP window size, etc. `IPriceOracle` does not provide any mechanism for consumer contracts to provide these parameters because doing so would require them to understand specifics of underlying price oracles, defeating the purpose of the abstraction.

When different parameters are appropriate for different consumers or under different circumstances, separate providers should be deployed, one for each configuration. In our implementation, most adapters and components accept these parameters as constructor arguments and store them as immutable variables.

By using an oracle consumers implicitly accept various trust assumptions and risks that cannot be encoded as parameters in the provider. Examples include the quality of price data, the stability of oracle software, and the involvement of trusted actors. These conditions fall outside of the scope of `IPriceOracle` providers thus making consumers responsible for researching and assessing them before integrating a particular oracle system. 

## Implementation

We have built an opinionated yet flexible set of contracts that implement `IPriceOracle`. This implementation is intended both as a reference implementation and as a production-ready system.

The implementation consists of the following classes of components, all of which implement the `IPriceOracle` interface:

* Adapters: Connectors that query external pricing sources and normalise their results.
* EulerRouter: A configurable dispatcher that delegates pricing to other `IPriceOracle` providers.
* Aggregates and Wrappers: `IPriceOracle` providers that combine or manipulate the results from other pricing sources.

We refer to our implementation as *modular* because these components can be combined and substituted with each other without requiring custom coding.


### Adapters

An adapter is a minimal, fully immutable contract that queries an external price feed. It is the atomic building block of the modular system, and most pricing queries ultimately end up consulting one or more adapters.

* Minimally Responsible: An adapter connects to one pricing system and queries a single price feed in that system.
* Bidirectional: An adapter works in both directions. If it supports quoting X/Y it must also support Y/X.
* Observable: An adapter's parameters and acceptance logic are easily observed on-chain.

Adapters inherit from the `BaseAdapter` contract. This verifies that the `IPriceOracle` interface is fully implemented and includes some internal convenience methods. Most adapters use the `ScaleUtils` library, which provides a structured system for scaling token amounts due to differences in decimals. Tokens that do not implement a `decimals()` method are assumed to have 18 decimals.

Adapters can be divided into two high-level classes: Those that connect to push-based oracles, and those that connect to pull-based oracles.

#### Push-Based

The traditionally most common type of oracle is push-based. This means that some external system pushes prices onto the blockchain, and an adapter can simply read and use the most up-to-date version currently stored. The frequency of updates can be periodic, depend on the price-volatility of the asset, or both.

The canonical example of a push-based oracle is Chainlink: An incentivised collection of operators monitor prices off-chain, and will pay the gas to update a storage location whenever the price moves a certain percentage. Uniswap 3 TWAPs can also be considered push-based, since the oracle is updated by swappers, and is always available to be read by price consumers.

#### Pull-Based

Pull-based oracles must be actively updated by price consumers. If the oracle is not updated, reading the price will fail. Typically, a price consumer will have to provide a message that was signed by a trusted off-chain oracle provider. The pull-based oracle will validate the signature and, if valid, will allow the price to be used. It may cache this price for a period of time, so the price may be read in the near future without having to provide another signed message.

Because `IPriceOracle` users are agnostic of the type of oracle, there is no way to pass a price update through the `getQuote`/`getQuotes` methods. For this reason, the oracles must be updated independently, prior to reading the price. The method for doing this is oracle-specific. Consumers are encouraged to use a multicall contract such as the [EVC](https://github.com/euler-xyz/ethereum-vault-connector) to update the price and retrieve it in the same transaction.

Some pull-based oracles such as Pyth have a single dedicated contract that verifies and caches the price update. For these, adapters can simply attempt to read the cached value, and the update is entirely out of scope of our implementation. For other oracles such as Redstone, there is no dedicated contract and instead price users are supposed to use a provided library to verify the update. In this case, the adapter itself exposes an update method and caches the update in its own storage.


### Router

The `EulerRouter` component contains an internal mapping from pairs to adapters. When queried with the `getQuote`/`getQuotes` methods, it attempts to resolve the query using the following algorithm:

1. If base and quote are the same, simply return the input amount.
2. If there is a mapping for the provided pair, query the configured adapter and return the result.
3. If the base asset is configured as a resolvable vault, then use the ERC-4626 `convertAssets` method to convert the input amount of shares to the underlying token amount, substitute the input amount for this value, change the base to the vault's underlying token, and restart the algorithm. Note that not all ERC-4626 vaults implement `convertAssets` [securely enough](#erc-4626) to be used for price oracles.
4. If a fallback oracle is configured, query it and return the result, otherwise fail with a `PriceOracle_NotSupported` error.

If an invocation to an external `IPriceOracle` provider fails, the error is propagated (not handled). This means that a router will not attempt to call the fallback router in the event of an error. A given pair is mapped to at most one provider. If it is desired to use an alternate provider to recover from errors, the [OracleWithBackup](#experimental-components) component can be used. This could be placed in front of an individual adapter to handle failures for one particular pair, or in front of the router itself to handle all pairs.

Not invoking the fallback for handling error conditions allows an important use-case: A router can be installed in front of another router to override specific pairs, while only delegating pricing for pairs it has not configured.

Routers can be reconfigured by a governor, allowing managed pricing systems to be constructed. A router can be made immutable by transferring governor privileges to `address(0)`.

#### ERC-4626

As described above, the router can natively convert ERC-4626 vault shares into quantities of their underlying assets. It does this by calling the standard `convertToAssets()` method.

Special care should be taken when configuring a router to resolve vaults in this way. The ERC-4626 standard does not require that this method is secure for price oracle purposes. There are [several vectors](https://www.euler.finance/blog/exchange-rate-manipulation-in-erc4626-vaults) to manipulating vault conversion rates.

Vaults created with the [Euler Vault Kit](https://docs.euler.finance/euler-vault-kit-white-paper/#rounding) are believed to be secure, as is the MakerDAO [savings DAI](https://etherscan.io/address/0x83f20f44975d03b1b09e64809b757c47f942beea) implementation.



### CrossAdapter

The `CrossAdapter` can be used to combine two oracles that share a base or quote asset. For example, an adapter could be configured to provide an ETH/DAI price by querying an ETH/USDC provider followed by a DAI/USDC provider.


### Experimental Components

We have developed several experimental components that showcase some of the oracle designs that are possible under `IPriceOracle`. These are unaudited and subject to change.

* `OracleWithBackup`: Catches an error thrown by a provider and queries a backup. For multiple backups, this component can be chained.
* `LowHighOracle`: Aggregator component that queries two providers and averages them (for `getQuote`) or widens the spread to encompass both quotes (for `getQuotes`).
* `AnchoredOracle`: Component that queries two providers, one of which is the primary and the other the anchor. If the prices are too far apart, an error is thrown, otherwise the primary is returned.
* `FixedSpreadWrapper`: Wrapper component that adds a fixed percentage of spread between the bid and ask prices.
* `RateGrowthSentinel`: Wrapper component that will start failing if the rate has moved more rapidly than some configured threshold.
* `SequencerLivenessSentinel`: Wrapper component that checks if the [L2 sequencer is live](https://docs.chain.link/data-feeds/l2-sequencer-feeds) before querying the price.

Components can be used with any adapter or component underneath. What unlocks this composability is the quote-based interface of `IPriceOracle` which by design forces adapters to encapsulate vendor specifics.

## Appendices

### Precision Loss Example

Consider the case where a user requests a quote for a pair such as SHIB/USDC. This represents the worst-case for precision loss because each unit of SHIB has a very small value, and because USDC's amount representation has a small number of decimals (6).

If, without precision loss, the price for SHIB/USDC should be `0.000008936`, then converting 1 unit of SHIB into USDC would yield `0.000008` (rounding down) or `0.000009` (rounding up). If this conversion was used as a price, then it would be significantly incorrect and furthermore would not reflect many dramatic price changes.

To solve this, a larger amount of the base asset should be converted. For example, if using `getQuote`, `1e12` SHIB may be requested with the `inAmount` parameter, which will effectively treat USDC as an 18 decimal place token.

If using `getQuotes` in many cases there will be a known amount (ie, the size of a user's collateral or liability), and this amount can be used directly as `inAmount` to leverage the price oracle's rounding and [spread](#spreads) behaviour.

### Lending Application

Although `IPriceOracle` is suitable for many applications, it was originally designed with lending applications in mind.

In a typical lending application, users will deposit tokens as collateral which then allows them to borrow different tokens as liabilities. At any given time, the collateral should be more valuable than the liability by some safety buffer, allowing the collateral to be seized and used to repay the loan if necessary. The safety buffer is commonly expressed as a Loan-To-Value ratio (LTV).

The `getQuotes` method returns a lower and upper estimate of the price (bid and ask, respectively). This allows oracles to expose pricing uncertainty to the consumer. By using the bid amount to underestimate the collateral value and the ask amount to overestimate the liability value, a lending market can ensure that a loan's maximum allowed LTV is not exceeded, even in the event of price uncertainty.

Because `IPriceOracle` does not define the exact semantics of the bid and ask prices, special oracles can be devised that reflect pricing uncertainty in various ways. One possibility would be to consult a volatility index and use this to widen the bid-ask spread at peaks when the market is moving quickly. If the volatility index is updated more rapidly than the underlying oracle, this could provide an advance indication that prices may be inaccurate, and prevent loans from being initiated at dangerously high LTVs. In a sense, this mechanism could be considered a dynamic LTV, even though no lending-specific logic is required to exist in the price oracle, and the price oracle can continue to do what it does best: Estimate prices and decide how confident it is in those estimates.

While widening the spreads at times of price uncertainty can be useful for preventing the origination of new loans at dangerous LTVs, using wide bid-ask spreads to determine the LTV of existing loans is problematic. Just because an oracle has temporarily reduced confidence in its pricing does not mean that a loan should be liquidated at these prices. For this reason, it makes sense for lending markets to use the mid-point price, which can be considered the oracle's best estimate as to the fair-market-value within its reported bid-ask range. For this reason, lending markets may prefer to use the mid-point prices to determine whether an existing loan is in violation and is therefore eligible for liquidation.

There are several strategies that oracles may employ in order to serve a lending market:

* If an oracle is combining the prices from several pricing sources, it may choose to use the lowest of the source prices for the bid and the highest for the ask. The mid-point could be a mathematical average of the prices, in which case it would settle to a new value as the pricing sources converge. Alternatively, the mid-point could be the fastest-updating pricing source, so as to not delay liquidations.
* For some lending market designs, it is preferable if the mid-point moves "smoothly". In the Euler Vault Kit implementation, smoothly transitioning prices add precision to a dutch auction liquidation system that negotiates an optimally efficient liquidation bonus between a violator and liquidators. To facilitate this, the mid-point may incorporate a TWAP component at some level.
* "Size-aware" oracles that adjust the quote values depending on the `inAmount` parameter can be used to pessimise larger loans. The theory is that smaller loans can be liquidated at a better average price (because they have less price impact), so a higher LTV might be acceptable than large loans. Although currently securely estimating market depth on-chain is difficult, research in this area is on-going.
* Some oracles such as Pyth provide a "confidence interval" for their prices. With some research into scaling this, this can be used as an off-chain source of information to scaling bid-ask spreads.