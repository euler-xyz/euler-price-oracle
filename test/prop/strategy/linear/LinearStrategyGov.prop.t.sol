// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleGovPropTest} from "test/prop/EOracleGov.prop.t.sol";
import {LinearStrategy} from "src/strategy/linear/LinearStrategy.sol";

contract LinearStrategyGov_PropTest is EOracleGovPropTest {
    function _deployOracle() internal override returns (address) {
        return address(new LinearStrategy());
    }
}
