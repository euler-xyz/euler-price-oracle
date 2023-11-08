// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ChainlinkOracle} from "src/chainlink/ChainlinkOracle.sol";

contract ImmutableChainlinkOracle is ChainlinkOracle {
    constructor(address _feedRegistry, address _weth) ChainlinkOracle(_feedRegistry, _weth) {}

    function initConfig(address base, address quote) external {
        _initConfig(base, quote);
    }
}
