// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {ChainlinkAdapter} from "src/chainlink/ChainlinkAdapter.sol";
import {IStEth} from "src/lido/IStEth.sol";

contract WstEthOracle is ChainlinkAdapter {
    address public immutable stEth;
    address public immutable stEthFeed;

    constructor(address _weth, address _stEth, address _stEthFeed, address _feedRegistry)
        ChainlinkAdapter(_feedRegistry, _weth)
    {
        stEth = _stEth;
        stEthFeed = _stEthFeed;
    }

    function canQuote(uint256, address base, address quote) public view override returns (bool) {
        if (base == stEth && quote == weth) return true;
        if (base == weth && quote == stEth) return true;
        return false;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        if (!canQuote(inAmount, base, quote)) revert NotSupported(base, quote);
        bool inverse = base == weth;

        ChainlinkConfig memory config = ChainlinkConfig({
            feed: stEthFeed,
            maxStaleness: 6 hours,
            maxDuration: 15 minutes,
            baseDecimals: 18,
            quoteDecimals: 18,
            feedDecimals: 18,
            inverse: inverse
        });
        uint256 outAmount = _getQuoteWithConfig(config, inAmount); // stEth / Eth
        uint256 rate = IStEth(stEth).getPooledEthByShares(1 ether);

        return inverse ? outAmount * 1e18 / rate : outAmount * rate / 1e18;
    }
}
