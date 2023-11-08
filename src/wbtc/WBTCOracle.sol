// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ChainlinkOracle} from "src/chainlink/ChainlinkOracle.sol";

contract WbtcOracle is ChainlinkOracle {
    address public immutable wbtc;
    address public immutable wbtcBtcFeed;
    address public immutable btcEthFeed;

    constructor(address _weth, address _wbtc, address _wbtcBtcFeed, address _btcEthFeed, address _feedRegistry)
        ChainlinkOracle(_feedRegistry, _weth)
    {
        wbtc = _wbtc;
        wbtcBtcFeed = _wbtcBtcFeed;
        btcEthFeed = _btcEthFeed;
    }

    function canQuote(uint256, address base, address quote) public view override returns (bool) {
        if (base == wbtc && quote == weth) return true;
        if (base == weth && quote == wbtc) return true;
        return false;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        if (!canQuote(inAmount, base, quote)) revert NotSupported(base, quote);
        bool inverse = base == weth;

        ChainlinkConfig memory wbtcBtcConfig = ChainlinkConfig({
            feed: wbtcBtcFeed,
            maxStaleness: DEFAULT_MAX_STALENESS,
            maxDuration: DEFAULT_MAX_ROUND_DURATION,
            baseDecimals: 8,
            quoteDecimals: 8,
            feedDecimals: 8,
            inverse: inverse
        });
        uint256 wbtcBtcQuote = _getQuoteWithConfig(wbtcBtcConfig, inverse ? 1e8 : inAmount, base, quote); // wbtc / btc OR btc / wbtc

        ChainlinkConfig memory btcEthConfig = ChainlinkConfig({
            feed: btcEthFeed,
            maxStaleness: DEFAULT_MAX_STALENESS,
            maxDuration: DEFAULT_MAX_ROUND_DURATION,
            baseDecimals: 8,
            quoteDecimals: 18,
            feedDecimals: 18,
            inverse: inverse
        });
        uint256 btcEthQuote = _getQuoteWithConfig(btcEthConfig, inverse ? inAmount : 1e8, base, quote); // btc / eth OR eth / btc

        return wbtcBtcQuote * btcEthQuote / (inverse ? 1e8 : 1e18);
    }
}
