// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleGovPropTest} from "test/prop/EOracleGov.prop.t.sol";
import {SimpleAggregator} from "src/strategy/aggregator/SimpleAggregator.sol";

contract SimpleAggregatorGov_PropTest is EOracleGovPropTest {
    address ORACLE1 = makeAddr("ORACLE1");
    address ORACLE2 = makeAddr("ORACLE2");
    address ORACLE3 = makeAddr("ORACLE3");

    function _deployOracle() internal override returns (address) {
        address[] memory oracles = new address[](3);
        oracles[0] = ORACLE1;
        oracles[1] = ORACLE2;
        oracles[2] = ORACLE3;

        return address(new SimpleAggregator(oracles, 2, SimpleAggregator.Algorithm.MEDIAN));
    }
}
