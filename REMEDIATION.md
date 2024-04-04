# EVK Price Oracles Security Audit

## Static Analysis Findings

### GEL-01S: Inexistent Sanitization of Input Address

Acknowledged, won't fix. Installing `address(0)` as a governor is a feature of the suite, making the child contract immutable. We intend to deploy production oracles through factory contracts, which reduces the likelihood of human error.

### LOE-01S: Inexistent Sanitization of Input Addresses

Acknowledged, won't fix. We intend to deploy production oracles through factory contracts, which reduces the likelihood of human error.

### POE-01S: Illegible Numeric Value Representations

Fixed. The constant was removed after fixing POE-01M.

### ROE-01S: Inexistent Sanitization of Input Addresses

Fixed by removing `RethOracle` from the codebase. Upon further research, we concluded that the exchange rate provided by the Rocketpool contracts does not meet the standards of economic security to recommend it for use in lending markets. Instead, one of the rETH feeds among Chainlink, Redstone and Pyth should be used.

## Manual Review Findings

### COE-01M: Inexistent Validation of Acceptable Answer Range

Acknowledged, won't fix. We believe it's best not to have price limits on oracle adapters, as these are subjective and expose the consumer application to tail risks.

### COL-01M: Inexistent Registration of Chronicle Subscriber

Acknowledged and updated in-code documentation to reflect this exhibit. After discussing with the Chronicle team, production feeds have two methods, `kiss` and `diss`, allowing the Chronicle multisig to respectively add or remove a caller from the whitelsit. The default behavior is to deny access to the methods.

### COL-02M: Potentially Unsupported Function Signature

Fixed. Decimals are now fetched with `BaseAdapter::_getDecimals` which returns 18 if the `IERC20::decimals` call reverts. This also allows the represent non-ERC20 assets e.g. BTC or USD by convention.

### ERR-01M: Improper Oracle Resolution Mechanism

Fixed. `EulerRouter::govSetConfig` now also sets `oracles[quote][base]`.

### ERR-02M: Incorrect Oracle Resolution of EIP-4626 Vaults

Fixed by removing the branch.

After analyzing how `EulerRouter` is going to be used in our deployment, we concluded that when called `quote` will most likely be USD or ETH. Cases where `base` is a borrowable ERC4626 vault still stand, so that code path stays.

### LOE-01M: Potentially Stale Calculation of Exchange Rate (Asynchronous Rewards / Penalties)

Acknowledged, won't fix. We agree with the economic assessment, however the magnitude of the difference is too small to necessitate any changes in the logic of the oracle.

### POE-01M: Inexistent Configurability of Confidence Width

Fixed. Maximum acceptable confidence width is now set in the constructor.

### POE-02M: POE-02M: Inexistent Prevention of Overpayment

Acknowledged, won't fix.

Pyth updates are priced determinstically per byte of update data. Thus we assess the likelihood that "the update fee may change between a transaction's submission and a transaction's execution in the network" to be very low, only relevant in the rare case that the price per byte is changed by Pyth governance. Moreover, updates currently carry negligible value < 1000 wei, so the value lost can be considered dust.

Finally, since Pyth updates prices centrally on the host blockchain, one can call `Pyth::updatePriceFeeds` directly or via another contract with the appropriate safeguards, instead of calling `PythOracle::updatePrice`, without impacting the pricing functionality of existing deployments of `PythOracle`. This is a viable mitigation in the case that the severity of this issue increases due to upstream changes in Pyth's payment model.

### POE-03M: Potentially Unsupported Function Signature

Fixed. Decimals are now fetched with `BaseAdapter::_getDecimals` which returns 18 if the `IERC20::decimals` call reverts. This also allows the use of non-ERC20 assets e.g. BTC or USD by convention.

### POE-04M: Improper Validation of Exponent

Fixed. Zero price is now considered invalid. Positive exponent is now considered invalid. Negative exponents down to -20 are now considered valid.

### RCO-01M: Potentially Unsupported Function Signature

Fixed. Decimals are now fetched with `BaseAdapter::_getDecimals` which returns 18 if the `IERC20::decimals` call reverts. This also allows the use of non-ERC20 assets e.g. BTC or USD by convention.

### RCO-02M: Improper Assumption of Oracle Decimals

Fixed.

After confirming with the Redstone team, while feeds have 8 decimals by default, there is indeed capability for custom data feeds with different decimals. As of 3 April 2024, there is one data feed on the `primary-data-prod` cluster with 14 decimals, the "USDC.DAI" feed. The following json manifest specifies all production feeds: https://oracle-gateway-1.a.redstone.finance/data-packages/latest/redstone-primary-prod

Since feed decimals cannot be introspected on-chain, `_feedDecimals` is now a constructor parameter.

### RCO-03M: Inexistent Capability of Functionality Overrides

Acknowledged, won't fix.

Oracle adapters in the Price Oracles codebase are intended to be immutable. Circuit breakers and other risk measures arising from conditions that cannot be reliably deduced on-chain may exist on a higher-level layer e.g. a router contract. The governor of that contract may then change the resolved oracle for the given pair to another provider or another implementation.

### RCO-04M: Misconceived Data Staleness

Fixed.

There are now two notions of staleness in `RedstoneCoreOracle`, `maxPriceStaleness` and `maxCacheStaleness`. The former compares `block.timestamp` against the timestamp of the Redstone data package in `updatePrice`. The latter compares `block.timestamp` against the timestamp of the cached price in `_getQuote`.

To enforce `maxPriceStaleness` we override `validateTimestamp` from `RedstoneConsumerBase` to effectively set the accepted range of valid Redstone signed data package timestamps to `[block.timestamp - maxPriceStaleness, block.timestamp + 1 min]`. Note that we still allow for timestamps from the future, which we consider an artifact of the RedStone system that does not affect the security of our integration adversely.

We acknowledge and document that callers can choose the most suitable Redstone price in `[block.time - maxPriceStaleness, block.timestamp]` for their action. However this is a drawback of the local data verification model employed by Redstone Core that will be present to an extent in any integration.

### RCO-05M: Improper Integration of Redstone On-Demand Feeds

Disagree with analysis and severity.

The Price Oracles codebase is intended to be used as a part of the Euler Vault Kit (EVK) system. Due to Redstone's unique way of transmitting price updates, separating the verification and consumption of the price in `RedstoneCoreOracle` is the only way to have EVK vaults remain agnostic to the implementation details of Redstone. If `RedstoneCoreOracle::_getQuote` also decoded and verified the signed Redstone price, then the extra calldata would need to be special-cased in the vault code. In fact, the entire call chain leading to `getQuote` would also need to special-case this behavior. We believe that having this phantom behavior present itself depending on whether `EulerRouter` points to this particular implementation of `IPriceOracle` is a worse security problem than explicitly requiring the caller to update the price in a separate call prior to interaction.

We disagree with the assertion that "the oracles of the Euler Finance Oracle repository should not require active maintenance." Pull-based oracles need _active maintenance_ by definition as the caller is themselves responsible of transmitting the price data and updating the price. Furthermore, users are expected to interact with EVK vaults through the Ethereum Vault Connector (EVC), which has multicall functionality. The user can dispatch a call to `RedstoneCoreOracle::updatePrice` prior to interacting with the vault, ensuring atomicity.

The assertion that "`RedstoneCoreOracle` functions identically to the "classic" data feeds already provided by Redstone" is a non sequitur. Redstone Core and Redstone Classic are different oracle products with a different operating model and supported pairs. Redstone Classic feeds have fixed update conditions, whereas `RedstoneCoreOracle` has dynamic update conditions, chosen to an extent by the deployer and the caller, with no deviation threshold. Additionally, after the fix for RCO-04M that decouples price staleness from cache staleness, one can set `maxCacheStaleness=0`, effectively enforcing that `updatePrice` be called in the same block as `getQuote` (e.g. through the EVC). In this configuration, the integration that `RedstoneCoreOracle` provides will the exact same latency guarantees as any conventional integration of Redstone Core.

### ROE-01M: Potentially Stale Calculation of Exchange Rate (Asynchronous Rewards / Penalties)

Fixed by removing `RethOracle` from the codebase. Upon further research, we concluded that the exchange rate provided by the Rocketpool contracts does not meet the standards of economic security to recommend it for use in lending markets. Instead, one of the rETH feeds among Chainlink, Redstone and Pyth should be used.

### SDO-01M: Insecure Usage of Outdated Interest Rate Accumulator

Fixed according to recommendation. We used `FixedPointMathLib::rpow` from Solady and verified it is equivalent to the `rpow` implementation used in the DSR Pot.

### SUS-01M: Potential Increase of Acceptable Values

Acknowledged, won't fix. The code is safe from overflows for `inAmount < 2**128`. We consider this a safe operational assumption since it means we can handle up to 10^20 units of an 18-decimal token.

### SUS-02M: Potential Negation Overflow

Fixed. `ScaleUtils::calcScale(uint8,uint8,int8)` was removed after fixing POE-02C.

### UVO-01M: Insecure Typecasting Operation (TWAP)

Fixed. The constructor now reverts with `Errors.PriceOracle_InvalidConfiguration()` if `_twapWindow > uint32(type(int32).max)`.

### UVO-02M: Inexistent Validation of Observation Cardinality Length

Acknowledged, won't fix.

`UniswapV3Oracle` requires preparation before deployment and use. The pool must have sufficient total liquidity, enough full-range liquidity, and enough observations in the ring buffer to support the desired TWAP window. Increasing the observation cardinality is best done before deployment because of two main reasons. First, the appropriate cardinality for a given TWAP window is difficult to determine on-chain because it depends on block time metrics, which may be variable (especially on non-ossified blockchains such as L2s). Second, it takes time for the buffer's length to grow to its new cardinality, during which the oracle is inoperable.

### UVO-03M: Insecure Calculation of Mean Tick

Fixed. Copied the rounding-down logic from `OracleLibrary` v0.8. Note that the subtraction is _not_ wrapped in `unchecked`.

### UVO-04M: Potentially Insecure TWAP Window

Acknowledged, won't fix.

The appropriate minimum value is relative. The oracle may be used for the internal Synths project, which will likely need TWAP windows shorter than 30 minutes. Note that price manipulation is less severe for Synths than it is for the lending product.

### UVO-05M: Insecure Down-Casting Operation (Input Amount)

Invalid issue. The function reverts if `inAmount > type(uint128).max`.

## Code Style Findings

### ERR-01C: Imprecise Terminology

Acknowledged and updated documentation of the return argument in `_resolveOracle`.

### GEL-01C: Redundant Variable Caching

Fixed.

### LOE-01C: Potential Usage of Library

Acknowledged. Disagree with assessment that applying the change optimizes the code's legibility.
We believe that the code in its current form is more legible. When dealing with a feed, there is a natural concept of direction. If the feed is ETH/USD the inverse direction is USD/ETH. When dealing with an exchange rate adapter such as `LidoOracle`, `RethOracle` and `SDaiOracle` the forward direction is more implicit.

### POE-01C: Potentially Redundant Function Implementation

Fixed by removing the function. Callers are expected to update the Pyth price in an EVC batch prior to interacting with the relevant EVK vault.

### POE-02C: Redundant Handling of Positive Exponent

Fixed. Together with the fix for `POE-04M`, we removed `ScaleUtils::calcScale(uint8,uint8,int8)` and refactored `PythOracle::_getQuote` to call `ScaleUtils.from` directly. The `int8` variant never had its rightful place in the library anyway since it was only there to accomodate Pyth's unique data format.

## RCO-01C: Ineffectual Usage of Safe Arithmetics

Acknowledged, won't fix. Although the title and description of the issue are invalid, we acknowledge the recommendation to use `unchecked`. However, we prefer to leave the code as-is.

## ROE-01C: Potential Usage of Library

Fixed by removing `RethOracle` from the codebase. Upon further research, we concluded that the exchange rate provided by the Rocketpool contracts does not meet the standards of economic security to recommend it for use in lending markets. Instead, one of the rETH feeds among Chainlink, Redstone and Pyth should be used.

## SDO-01C: Potential Usage of Library

Acknowledged. Disagree with assessment that applying the change optimizes the code's legibility.
We believe that the code in its current form is more legible. When dealing with a feed, there is a natural concept of direction. If the feed is ETH/USD the inverse direction is USD/ETH. When dealing with an exchange rate adapter such as `LidoOracle`, `RethOracle` and `SDaiOracle` the forward direction is more implicit.

## SDO-02C: Repetitive Value Literal

Fixed. The code now uses `RAY` as a contract-level constant.

## SUS-01C: Inefficient Erasure of Upper Bits

Acknowledged. Disagree with assessment that applying the change optimizes the code's legibility.
