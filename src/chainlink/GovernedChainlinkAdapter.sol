// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable} from "@solady/auth/Ownable.sol";
import {ChainlinkAdapter} from "src/chainlink/ChainlinkAdapter.sol";

contract GovernedChainlinkAdapter is ChainlinkAdapter, Ownable {
    error FeedNotEnabled(address feed);

    constructor(address _feedRegistry, address _weth, address _owner) ChainlinkAdapter(_feedRegistry, _weth) {
        _initializeOwner(_owner);
    }

    function addConfig(address base, address quote, address feed, uint32 maxStaleness, uint32 maxDuration, bool inverse)
        external
        onlyOwner
    {
        bool isEnabled = feedRegistry.isFeedEnabled(feed);
        if (!isEnabled) revert FeedNotEnabled(feed);

        _setConfig(base, quote, feed, maxStaleness, maxDuration, inverse);
    }

    function removeConfig(address base, address quote) external onlyOwner {
        delete configs[base][quote];
        delete configs[quote][base];
    }
}
