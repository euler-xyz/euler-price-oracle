// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract ImmutableChainlinkOracle is ChainlinkOracle {
    constructor(address _feedRegistry, address _weth) ChainlinkOracle(_feedRegistry, _weth) {}

    function initConfig(address base, address quote) external {
        _initConfig(base, quote);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.ImmutableChainlinkOracle(uint256(DEFAULT_MAX_STALENESS));
    }
}
