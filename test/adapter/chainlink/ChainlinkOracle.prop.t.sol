// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOraclePropTest} from "test/EOracle.prop.t.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";

contract ChainlinkOracle_PropTest is EOraclePropTest {
    address GOVERNOR = makeAddr("GOVERNOR");
    address FEED_REGISTRY = makeAddr("FEED_REGISTRY");
    address WETH = makeAddr("WETH");

    function _deployOracle() internal override returns (address) {
        return address(new ChainlinkOracle(FEED_REGISTRY, WETH));
    }
}