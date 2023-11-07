// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ChainlinkAdapter} from "src/chainlink/ChainlinkAdapter.sol";

contract ImmutableChainlinkAdapter is ChainlinkAdapter {
    uint256 public constant MAX_ROUND_DURATION = 1 hours;
    uint256 public constant MAX_STALENESS = 1 days;

    constructor(address _feedRegistry, address _weth) ChainlinkAdapter(_feedRegistry, _weth) {}

    function initConfig(address base, address quote) external {
        _initConfig(base, quote);
    }
}
