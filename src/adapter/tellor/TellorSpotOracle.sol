// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {UsingTellor} from "@tellor/UsingTellor.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @dev we can optimize construction of queries quite a bit
contract TellorSpotOracle is BaseOracle, UsingTellor {
    /// @dev Tellor is an optimistic oracle so too recent values are not trusted.
    /// @custom:read https://tellor.io/best-practices-for-oracle-users-on-ethereum/
    uint256 public minStaleness;
    uint256 public maxStaleness;
    mapping(address base => mapping(address quote => Config)) public configs;

    struct Config {
        string asset;
        string denom;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        bool inverse;
    }

    struct ConfigParams {
        address base;
        address quote;
        string asset;
        string denom;
    }

    constructor(address payable _tellorAddress, uint256 _minStaleness, uint256 _maxStaleness)
        UsingTellor(_tellorAddress)
    {
        minStaleness = _minStaleness;
        maxStaleness = _maxStaleness;
    }

    function govSetConfig(ConfigParams memory config) external onlyGovernor {
        _setConfig(config);
    }

    function govUnsetConfig(address base, address quote) external onlyGovernor {
        delete configs[base][quote];
        delete configs[quote][base];
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.TellorSpotOracle(maxStaleness);
    }

    function _setConfig(ConfigParams memory config) internal {
        uint8 baseDecimals = ERC20(config.base).decimals();
        uint8 quoteDecimals = ERC20(config.quote).decimals();

        configs[config.base][config.quote] = Config({
            asset: config.asset,
            denom: config.denom,
            baseDecimals: baseDecimals,
            quoteDecimals: quoteDecimals,
            inverse: false
        });

        configs[config.quote][config.base] = Config({
            asset: config.asset,
            denom: config.denom,
            baseDecimals: quoteDecimals,
            quoteDecimals: baseDecimals,
            inverse: true
        });
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        Config memory config = configs[base][quote];
        if (bytes(config.asset).length == 0) revert Errors.ConfigDoesNotExist(base, quote);

        bytes32 queryId = keccak256(abi.encode("SpotPrice", abi.encode(config.asset, config.denom)));
        uint256 maxTimestamp = block.timestamp - minStaleness;
        (bytes memory answer, uint256 updatedAt) = getDataBefore(queryId, maxTimestamp);
        if (updatedAt == 0) revert Errors.EOracle_NoAnswer();

        uint256 staleness = block.timestamp - updatedAt;
        if (staleness > maxStaleness) revert Errors.EOracle_TooStale(staleness, maxStaleness);

        uint256 price = abi.decode(answer, (uint256));
        if (price == 0) revert Errors.Tellor_InvalidPrice(price);

        if (!config.inverse) return inAmount * price / 10 ** config.baseDecimals;
        else return inAmount * 10 ** config.quoteDecimals / price;
    }
}
