# EOracle Specification
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED",  "MAY", and "OPTIONAL" in this document are to be interpreted as described in [RFC 2119](https://datatracker.ietf.org/doc/html/rfc2119).
## Definitions
- **Asset:** An ERC20 token (denoted by its contract address), a currency (denoted by its ISO 4217 numeric code) or the native coin (denoted by `0xEeee...EEeE`).
- **Base:** The asset which is being priced.
- **Quote:** The asset which is used as the unit of account for the base.
- **EOracle:** Smart contract that implements the `IEOracle` interface. EOracles can be composed together as part of the Euler Oracles framework. They either interface with external pricing providers or serve as utility layers.
- **Adapter:** An EOracle that directly connects to external contracts or systems that provide pricing. An adapter validates the data and casts it to the common `IEOracle` interface. An adapter may connect to canonical oracle systems like Chainlink, query DeFi contracts, or apply a hard-coded exchange rate.
- **Strategy:** An EOracle that serves as an intermediary logic layer. Strategies forward calls to several EOracles and combine the results into a single price.
- **Configuration tree:** A tree data structure composed of EOracles nodes that defines a self-contained oracle configuration.

## Interface
Code: [IEOracle.sol](../src/interfaces/IEOracle.sol)
```solidity
interface IEOracle {
    /// @notice One-sided price: How much quote token you would get for inAmount of base token, assuming no price spread
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @return outAmount The amount of `quote` that is equivalent to `inAmount` of `base`.
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount);
 
    /// @notice Two-sided price: How much quote token you would get/spend for selling/buying inAmount of base token
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @return bidOutAmount The amount of `quote` you would get for selling `inAmount` of `base`.
    /// @return askOutAmount The amount of `quote` you would get for buying `inAmount` of `base`.
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        returns (uint256 bidOutAmount, uint256 askOutAmount);
}

```
## Methods
Oracles MUST implement `description`, `getQuote` and `getQuotes` as defined by the `IEOracle` interface. The methods MUST behave as specified in this section.

### `getQuote` and `getQuotes`
- MUST NOT return 0. If `outAmount` is calculated to be 0, then the EOracle MUST revert with `EOracle_InvalidAnswer`.
- MUST support values for `inAmount` in the range `[1, 2^128-1]`. 
- SHOULD support values for `inAmount` in the range `[2^128, 2^256-1]` whenever possible.
- MUST revert with `EOracle_NotSupported` if the EOracle does not support the given base/quote pair. Note that the set of supported pairs may change throughout the lifecycle of the EOracle.
- MUST revert with `EOracle_TooStale` if the external system reports a price that is too old to be trusted.
- If an external contract reverts the EOracle MAY revert with `EOracle_NoAnswer` or bubble up the vendor-specific error.

### `getQuote`
- MUST return the amount of `quote` that is price-equivalent to `inAmount` of `base` without accounting for spread due to slippage, fees or other on-chain conditions.

### `getQuotes`
- MUST return the bid amount and ask amount of `quote` that is price-equivalent to `inAmount` of `base` by accounting for spread due to slippage, fees or other on-chain conditions.
- SHOULD return a zero-spread price if the external system does not support spread quotes.

## Denominations
Source: [src/lib/Denominations.sol](src/lib/Denominations.sol)

Base and quote are `address` types that represent assets according to the following system:
- MUST denote an ERC20 token by its contract address on the host blockchain.
- MUST denote the native coin on the host blockchain by `0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE` IF the native coin does not implement ERC20.
- MUST denote the native coin on the host blockchain by its contract address IF the native coin implements ERC20.
- MUST denote a national currency or precious metal by its numeric code as defined by ISO 4217, type-cast to `address`.
- MUST adapt the nomenculature of external price feeds to the one defined by Euler Oracles.
- SHOULD avoid supporting coins or tokens on external blockchains and instead denominate in their wrapped or bridged versions on the host blockchain.
- MAY treat the native coin and its canonical wrapper as interchangeable assets. Note that this may entail additional risks if the wrapper contract is mutable, pausable, governed or upgradeable.
- MAY use the ISO 4217 "No currency" code (999) to denote an unknown asset. Operations involving such assets MUST revert.
- MAY implement an extension to this standard by providing an alternative unambiguous, domain-separated, and observable standard of denomination.