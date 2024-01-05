// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleGovPropTest} from "test/prop/EOracleGov.prop.t.sol";
import {SimpleRouter} from "src/strategy/router/SimpleRouter.sol";

contract SimpleRouterGov_PropTest is EOracleGovPropTest {
    address FALLBACK = makeAddr("FALLBACK");

    function _deployOracle() internal override returns (address) {
        return address(new SimpleRouter(FALLBACK));
    }
}
