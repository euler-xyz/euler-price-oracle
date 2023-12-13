// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOraclePropTest} from "test/prop/EOracle.prop.t.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";

contract ChainlinkOracle_PropTest is EOraclePropTest {
    address GOVERNOR = makeAddr("GOVERNOR");
    address CHAINLINK_FEED_REGISTRY = makeAddr("CHAINLINK_FEED_REGISTRY");
    address WETH = makeAddr("WETH");

    function _deployOracle() internal override returns (address) {
        return address(new ChainlinkOracle(CHAINLINK_FEED_REGISTRY, WETH));
    }
}
