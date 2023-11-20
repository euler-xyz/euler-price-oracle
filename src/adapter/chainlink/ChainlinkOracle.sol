// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Denominations} from "@chainlink/Denominations.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {FeedRegistryInterface} from "@chainlink/interfaces/FeedRegistryInterface.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

abstract contract ChainlinkOracle {
    uint32 public constant DEFAULT_MAX_ROUND_DURATION = 1 hours;
    uint32 public constant DEFAULT_MAX_STALENESS = 1 days;
    FeedRegistryInterface public immutable feedRegistry;
    address public immutable weth;
    mapping(address base => mapping(address quote => ChainlinkConfig)) public configs;

    event ConfigSet(address indexed base, address indexed quote, address indexed feed);

    struct ChainlinkConfig {
        address feed;
        uint32 maxStaleness;
        uint32 maxDuration;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        uint8 feedDecimals;
        bool inverse;
    }

    error CallReverted(bytes reason);
    error InvalidAnswer(int256 answer);
    error NoFeedConfigured(address base, address quote);
    error NotSupported(address base, address quote);
    error PriceTooStale(uint256 staleness, uint256 maxStaleness);
    error RoundIncomplete();
    error RoundTooLong(uint256 duration, uint256 maxDuration);

    constructor(address _feedRegistry, address _weth) {
        feedRegistry = FeedRegistryInterface(_feedRegistry);
        weth = _weth;
    }

    function canQuote(uint256, address base, address quote) external view virtual returns (bool) {
        ChainlinkConfig memory config = _getConfig(base, quote);
        if (config.feed == address(0)) return false;
        return true;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view virtual returns (uint256) {
        ChainlinkConfig memory config = _getConfig(base, quote);
        return _getQuoteWithConfig(config, inAmount, base, quote);
    }

    function _getQuoteWithConfig(ChainlinkConfig memory config, uint256 inAmount, address base, address quote)
        internal
        view
        returns (uint256)
    {
        bytes memory data;
        if (config.feed == address(feedRegistry)) {
            (address asset, address denom,) = _getAssetAndDenom(base, quote);
            data = abi.encodeCall(FeedRegistryInterface.latestRoundData, (asset, denom));
        } else {
            data = abi.encodeCall(AggregatorV3Interface.latestRoundData, ());
        }

        (bool success, bytes memory returnData) = config.feed.staticcall(data);
        if (!success) revert CallReverted(returnData);

        (, int256 answer, uint256 startedAt, uint256 updatedAt,) =
            abi.decode(returnData, (uint80, int256, uint256, uint256, uint80));

        if (answer <= 0) revert InvalidAnswer(answer);
        if (updatedAt == 0) revert RoundIncomplete();

        uint256 roundDuration = updatedAt - startedAt;
        if (roundDuration > config.maxDuration) {
            revert RoundTooLong(roundDuration, config.maxDuration);
        }

        uint256 staleness = block.timestamp - updatedAt;
        if (staleness >= config.maxStaleness) {
            revert PriceTooStale(staleness, config.maxStaleness);
        }

        uint256 unitPrice = uint256(answer);

        if (config.inverse) return (inAmount * 10 ** config.quoteDecimals) / unitPrice;
        else return (inAmount * unitPrice) / 10 ** config.baseDecimals;
    }

    function _getConfig(address base, address quote) internal view returns (ChainlinkConfig memory) {
        ChainlinkConfig memory config = configs[base][quote];
        if (config.feed == address(0)) revert NoFeedConfigured(base, quote);
        return config;
    }

    function _setConfig(
        address base,
        address quote,
        address feed,
        uint32 maxStaleness,
        uint32 maxDuration,
        bool inverse
    ) internal returns (ChainlinkConfig memory) {
        uint8 baseDecimals = ERC20(base).decimals();
        uint8 quoteDecimals = ERC20(quote).decimals();
        uint8 feedDecimals = AggregatorV3Interface(feed).decimals();

        ChainlinkConfig memory config = ChainlinkConfig({
            feed: feed,
            maxStaleness: maxStaleness,
            maxDuration: maxDuration,
            baseDecimals: baseDecimals,
            quoteDecimals: quoteDecimals,
            feedDecimals: feedDecimals,
            inverse: inverse
        });
        configs[base][quote] = config;
        return config;
    }

    function _initConfig(address base, address quote) internal returns (ChainlinkConfig memory) {
        (address asset, address denom, bool inverse) = _getAssetAndDenom(base, quote);
        address feed = address(feedRegistry.getFeed(asset, denom));

        uint8 baseDecimals = ERC20(base).decimals();
        uint8 quoteDecimals = ERC20(quote).decimals();
        uint8 feedDecimals = AggregatorV3Interface(feed).decimals();

        ChainlinkConfig memory config = ChainlinkConfig({
            feed: address(feedRegistry),
            maxStaleness: DEFAULT_MAX_STALENESS,
            maxDuration: DEFAULT_MAX_ROUND_DURATION,
            baseDecimals: baseDecimals,
            quoteDecimals: quoteDecimals,
            feedDecimals: feedDecimals,
            inverse: inverse
        });

        configs[base][quote] = config;

        ChainlinkConfig memory invConfig = ChainlinkConfig({
            feed: address(feedRegistry),
            maxStaleness: DEFAULT_MAX_STALENESS,
            maxDuration: DEFAULT_MAX_ROUND_DURATION,
            baseDecimals: quoteDecimals,
            quoteDecimals: baseDecimals,
            feedDecimals: feedDecimals,
            inverse: !inverse
        });

        configs[quote][base] = invConfig;
        emit ConfigSet(base, quote, address(feedRegistry));

        return config;
    }

    function _getFeedDecimals(address asset, address denom) internal pure returns (uint8) {
        if (denom != Denominations.ETH) revert NotSupported(asset, denom);
        return 18;
    }

    function _getAssetAndDenom(address base, address quote) internal view returns (address, address, bool) {
        if (quote == weth) return (base, Denominations.ETH, false);
        if (base == weth) return (quote, Denominations.ETH, true);

        revert NotSupported(base, quote);
    }
}
