// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleDescPropTest} from "test/prop/EOracleDesc.prop.t.sol";
import {SimpleRouter} from "src/strategy/router/SimpleRouter.sol";

contract SimpleRouterDesc_PropTest is EOracleDescPropTest {
    address FALLBACK = makeAddr("FALLBACK");

    function _deployOracle() internal override returns (address) {
        return address(new SimpleRouter(FALLBACK));
    }
}
