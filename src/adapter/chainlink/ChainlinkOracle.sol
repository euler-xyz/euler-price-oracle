// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {FeedRegistryInterface} from "@chainlink/interfaces/FeedRegistryInterface.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {Denominations} from "src/lib/Denominations.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author totomanov
/// @notice Adapter for Chainlink Push Oracles.
contract ChainlinkOracle is BaseOracle {
    /// @dev The address of the Chainlink Feed Registry.
    /// 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf on Ethereum Mainnet.
    FeedRegistryInterface public immutable feedRegistry;
    /// @dev The address of Wrapped Ether.
    address public immutable weth;
    /// @dev Oracle configurations for a given base/quote pair.
    /// This mapping is populated symmetrically. When setting base/quote,
    /// the inverse path quote/base is also populated.
    mapping(address base => mapping(address quote => Config)) public configs;

    event ConfigSet(address indexed base, address indexed quote, address indexed feed);
    event ConfigUnset(address indexed base, address indexed quote);

    struct Config {
        address feed;
        uint32 maxStaleness;
        uint32 maxDuration;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        bool inverse;
    }

    struct ConfigParams {
        address base;
        address quote;
        address feed;
        uint32 maxStaleness;
        uint32 maxDuration;
        bool inverse;
    }

    constructor(address _feedRegistry, address _weth) {
        feedRegistry = FeedRegistryInterface(_feedRegistry);
        weth = _weth;
    }

    function govSetConfig(ChainlinkOracle.ConfigParams memory params) external onlyGovernor {
        _setConfig(params);
    }

    function govUnsetConfig(address base, address quote) external onlyGovernor {
        delete configs[base][quote];
        delete configs[quote][base];

        emit ConfigUnset(base, quote);
        emit ConfigUnset(quote, base);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view virtual returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        virtual
        returns (uint256, uint256)
    {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function description() external view virtual returns (OracleDescription.Description memory) {
        return OracleDescription.ChainlinkOracle(0, governor);
    }

    function _setConfig(ConfigParams memory config) internal {
        uint8 baseDecimals = ERC20(config.base).decimals();
        uint8 quoteDecimals = ERC20(config.quote).decimals();

        configs[config.base][config.quote] = Config({
            feed: config.feed,
            maxStaleness: config.maxStaleness,
            maxDuration: config.maxDuration,
            baseDecimals: baseDecimals,
            quoteDecimals: quoteDecimals,
            inverse: config.inverse
        });

        configs[config.quote][config.base] = Config({
            feed: config.feed,
            maxStaleness: config.maxStaleness,
            maxDuration: config.maxDuration,
            baseDecimals: quoteDecimals,
            quoteDecimals: baseDecimals,
            inverse: !config.inverse
        });

        emit ConfigSet(config.base, config.quote, config.feed);
        emit ConfigSet(config.quote, config.base, config.feed);
    }

    function _getQuote(uint256 inAmount, address base, address quote) internal view returns (uint256) {
        Config memory config = _getConfigOrRevert(base, quote);
        bytes memory data;
        if (config.feed == address(feedRegistry)) {
            (address asset, address denom) = _getAssetAndDenom(base, quote);
            data = abi.encodeCall(FeedRegistryInterface.latestRoundData, (asset, denom));
        } else {
            data = abi.encodeCall(AggregatorV3Interface.latestRoundData, ());
        }

        (bool success, bytes memory returnData) = config.feed.staticcall(data);
        if (!success) revert Errors.Chainlink_CallReverted(returnData);

        (, int256 answer, uint256 startedAt, uint256 updatedAt,) =
            abi.decode(returnData, (uint80, int256, uint256, uint256, uint80));

        if (answer <= 0) revert Errors.Chainlink_InvalidAnswer(answer);
        if (updatedAt == 0) revert Errors.Chainlink_RoundIncomplete();

        uint256 roundDuration = updatedAt - startedAt;
        if (roundDuration > config.maxDuration) {
            revert Errors.Chainlink_RoundTooLong(roundDuration, config.maxDuration);
        }

        uint256 staleness = block.timestamp - updatedAt;
        if (staleness > config.maxStaleness) {
            revert Errors.EOracle_TooStale(staleness, config.maxStaleness);
        }

        uint256 unitPrice = uint256(answer);
        return config.inverse
            ? (inAmount * 10 ** config.quoteDecimals) / unitPrice
            : (inAmount * unitPrice) / 10 ** config.baseDecimals;
    }

    function _getConfigOrRevert(address base, address quote) internal view returns (Config memory) {
        Config memory config = configs[base][quote];
        if (config.feed == address(0)) revert Errors.EOracle_NotSupported(base, quote);
        return config;
    }

    function _getAssetAndDenom(address base, address quote) internal view returns (address, address) {
        base = base == weth ? Denominations.ETH : base;
        quote = quote == weth ? Denominations.ETH : quote;
        return (base, quote);
    }
}
