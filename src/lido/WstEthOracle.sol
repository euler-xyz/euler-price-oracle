// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ChainlinkOracle} from "src/chainlink/ChainlinkOracle.sol";
import {IWstEth} from "src/lido/IWstEth.sol";

contract WstEthOracle is ChainlinkOracle {
    address public immutable stEth;
    address public immutable wstEth;
    address public immutable stEthFeed;

    constructor(address _weth, address _stEth, address _wstEth, address _stEthFeed, address _feedRegistry)
        ChainlinkOracle(_feedRegistry, _weth)
    {
        stEth = _stEth;
        wstEth = _wstEth;
        stEthFeed = _stEthFeed;
    }

    function canQuote(uint256, address base, address quote) public view override returns (bool) {
        if (base == wstEth && quote == weth) return true;
        if (base == weth && quote == wstEth) return true;
        return false;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        if (!canQuote(inAmount, base, quote)) revert NotSupported(base, quote);
        bool inverse = base == weth;

        ChainlinkConfig memory config = ChainlinkConfig({
            feed: stEthFeed,
            maxStaleness: DEFAULT_MAX_STALENESS,
            maxDuration: DEFAULT_MAX_ROUND_DURATION,
            baseDecimals: 18,
            quoteDecimals: 18,
            feedDecimals: 18,
            inverse: inverse
        });
        uint256 outAmount = _getQuoteWithConfig(config, inAmount, base, quote);

        if (!inverse) {
            // outAmount is stEth / Eth
            uint256 wstEthToStEth = IWstEth(wstEth).stEthPerToken();
            return outAmount * wstEthToStEth / 1e18;
        } else {
            // outAmount is Eth / stEth
            uint256 stEthToWstEth = IWstEth(wstEth).tokensPerStEth(); // stEth / wstEth
            return outAmount * stEthToWstEth / 1e18;
        }
    }
}
