// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleGovPropTest} from "test/prop/EOracleGov.prop.t.sol";
import {SimpleRouter} from "src/strategy/router/SimpleRouter.sol";

contract SimpleRouterGov_PropTest is EOracleGovPropTest {
    address FALLBACK = makeAddr("FALLBACK");

    function _deployOracle() internal override returns (address) {
        return address(new SimpleRouter(FALLBACK));
    }

    function _govMethods() internal pure override returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](3);
        selectors[0] = SimpleRouter.govSetConfig.selector;
        selectors[1] = SimpleRouter.govUnsetConfig.selector;
        selectors[2] = SimpleRouter.govSetFallbackOracle.selector;
        return selectors;
    }
}
