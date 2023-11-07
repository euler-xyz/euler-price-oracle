// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ChainlinkAdapter} from "src/chainlink/ChainlinkAdapter.sol";
import {IStEth} from "src/lido/IStEth.sol";

contract WBTCOracle is ChainlinkAdapter {
    address public immutable wbtc;
    address public immutable wbtcBtcFeed;
    address public immutable btcEthFeed;

    constructor(address _weth, address _wbtc, address _wbtcBtcFeed, address _btcEthFeed, address _feedRegistry)
        ChainlinkAdapter(_feedRegistry, _weth)
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
            maxStaleness: 6 hours,
            maxDuration: 15 minutes,
            baseDecimals: 8,
            quoteDecimals: 8,
            feedDecimals: 8,
            inverse: inverse
        });
        uint256 wbtcBtcQuote = _getQuoteWithConfig(wbtcBtcConfig, inverse ? 1e8 : inAmount); // wbtc / btc OR btc / wbtc

        ChainlinkConfig memory btcEthConfig = ChainlinkConfig({
            feed: btcEthFeed,
            maxStaleness: 6 hours,
            maxDuration: 15 minutes,
            baseDecimals: 8,
            quoteDecimals: 18,
            feedDecimals: 18,
            inverse: inverse
        });
        uint256 btcEthQuote = _getQuoteWithConfig(btcEthConfig, inverse ? inAmount : 1e8); // btc / eth OR eth / btc

        return wbtcBtcQuote * btcEthQuote / (inverse ? 1e8 : 1e18);
    }
}
