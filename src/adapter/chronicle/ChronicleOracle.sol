// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IChronicle} from "@chronicle-std/IChronicle.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract ChronicleOracle is BaseOracle {
    struct Config {
        address feed;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        bool inverse;
    }

    struct ConfigParams {
        address base;
        address quote;
        address feed;
    }

    uint256 public immutable maxStaleness;
    mapping(address base => mapping(address quote => Config)) public configs;

    constructor(uint256 _maxStaleness) {
        maxStaleness = _maxStaleness;
    }

    function govSetConfig(ConfigParams[] memory params) external onlyGovernor {
        uint256 length = params.length;
        for (uint256 i = 0; i < length;) {
            _setConfig(params[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.ImmutableChronicleOracle(maxStaleness);
    }

    function _setConfig(ConfigParams memory params) internal {
        address base = params.base;
        address quote = params.quote;
        address feed = params.feed;

        if (configs[base][quote].feed != address(0)) revert Errors.ConfigExists(base, quote);

        uint8 baseDecimals = ERC20(base).decimals();
        uint8 quoteDecimals = ERC20(quote).decimals();
        configs[base][quote] =
            Config({feed: feed, baseDecimals: baseDecimals, quoteDecimals: quoteDecimals, inverse: false});

        configs[quote][base] =
            Config({feed: feed, baseDecimals: quoteDecimals, quoteDecimals: baseDecimals, inverse: true});
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        Config memory config = configs[base][quote];
        if (config.feed == address(0)) revert Errors.EOracle_NotSupported(base, quote);

        (uint256 unitPrice, uint256 age) = IChronicle(config.feed).readWithAge();
        if (age > maxStaleness) revert Errors.EOracle_TooStale(age, maxStaleness);

        if (config.inverse) return (inAmount * 10 ** config.quoteDecimals) / unitPrice;
        else return (inAmount * unitPrice) / 10 ** config.baseDecimals;
    }
}
