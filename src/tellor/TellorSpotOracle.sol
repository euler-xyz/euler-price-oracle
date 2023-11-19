// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {UsingTellor} from "@tellor/UsingTellor.sol";

/// @dev we can optimize construction of queries quite a bit
contract TellorSpotOracle is UsingTellor {
    /// @dev Tellor is an optimistic oracle so too recent values are not trusted.
    /// @custom:read https://tellor.io/best-practices-for-oracle-users-on-ethereum/
    uint256 public immutable minStaleness;
    uint256 public immutable maxStaleness;

    struct TellorConfig {
        string asset;
        string denom;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        bool inverse;
    }

    mapping(address base => mapping(address quote => TellorConfig)) public configs;

    error ArityMismatch(uint256 arityA, uint256 arityB);
    error ConfigAlreadyExists(address base, address quote);
    error ConfigDoesNotExist(address base, address quote);
    error CouldNotPrice();
    error InvalidPrice(uint256 price);
    error PriceTooStale(uint256 staleness, uint256 maxStaleness);

    struct InitTellorConfig {
        address base;
        address quote;
        string asset;
        string denom;
    }

    constructor(
        address payable _tellorAddress,
        uint256 _minStaleness,
        uint256 _maxStaleness,
        InitTellorConfig[] memory _configs
    ) UsingTellor(_tellorAddress) {
        minStaleness = _minStaleness;
        maxStaleness = _maxStaleness;

        uint256 length = _configs.length;
        for (uint256 i = 0; i < length;) {
            _initConfig(_configs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        TellorConfig memory config = configs[base][quote];
        if (bytes(config.asset).length == 0) revert ConfigDoesNotExist(base, quote);

        bytes32 queryId = keccak256(abi.encode("SpotPrice", abi.encode(config.asset, config.denom)));
        uint256 maxTimestamp = block.timestamp - minStaleness;
        (bytes memory answer, uint256 updatedAt) = getDataBefore(queryId, maxTimestamp);
        if (updatedAt == 0) revert CouldNotPrice();

        uint256 staleness = block.timestamp - updatedAt;
        if (staleness > maxStaleness) revert PriceTooStale(staleness, maxStaleness);

        uint256 price = abi.decode(answer, (uint256));
        if (price == 0) revert InvalidPrice(price);

        if (!config.inverse) return inAmount * price / 10 ** config.baseDecimals;
        else return inAmount * 10 ** config.quoteDecimals / price;
    }

    function canQuote(uint256, address base, address quote) external view returns (bool) {
        TellorConfig memory config = configs[base][quote];
        return bytes(config.asset).length > 0;
    }

    function _initConfig(InitTellorConfig memory config) internal {
        uint8 baseDecimals = ERC20(config.base).decimals();
        uint8 quoteDecimals = ERC20(config.quote).decimals();

        configs[config.base][config.quote] = TellorConfig({
            asset: config.asset,
            denom: config.denom,
            baseDecimals: baseDecimals,
            quoteDecimals: quoteDecimals,
            inverse: false
        });

        configs[config.quote][config.base] = TellorConfig({
            asset: config.asset,
            denom: config.denom,
            baseDecimals: quoteDecimals,
            quoteDecimals: baseDecimals,
            inverse: true
        });
    }
}
