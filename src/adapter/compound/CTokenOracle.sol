// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";

contract CTokenOracle is ChainlinkOracle {
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

        ChainlinkConfig memory btcEthConfig = ChainlinkConfig({
            feed: btcEthFeed,
            maxStaleness: DEFAULT_MAX_STALENESS,
            maxDuration: DEFAULT_MAX_ROUND_DURATION,
            baseDecimals: 8,
            quoteDecimals: 18,
            feedDecimals: 18,
            inverse: inverse
        });

        // todo: fix precision loss, e.g. 1 sat WBTC is quoted as 0 WETH

        if (!inverse) {
            uint256 wbtcBtcQuote = _getQuoteWithConfig(wbtcBtcConfig, inAmount, base, quote);
            uint256 btcEthQuote = _getQuoteWithConfig(btcEthConfig, 1e8, base, quote);
            return wbtcBtcQuote * btcEthQuote / 1e8;
        } else {
            uint256 ethBtcQuote = _getQuoteWithConfig(btcEthConfig, inAmount, base, quote);
            uint256 btcWbtcQuote = _getQuoteWithConfig(wbtcBtcConfig, 1e8, base, quote);
            return ethBtcQuote * btcWbtcQuote / 1e18;
        }
    }
}
