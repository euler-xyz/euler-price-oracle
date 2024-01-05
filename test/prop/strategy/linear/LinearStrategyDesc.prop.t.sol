// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleDescPropTest} from "test/prop/EOracleDesc.prop.t.sol";
import {LinearStrategy} from "src/strategy/linear/LinearStrategy.sol";

contract LinearStrategyDesc_PropTest is EOracleDescPropTest {
    function _deployOracle() internal override returns (address) {
        return address(new LinearStrategy());
    }
}
