// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleDescPropTest} from "test/prop/EOracleDesc.prop.t.sol";
import {WstEthOracle} from "src/adapter/lido/WstEthOracle.sol";

contract WstEthOracleDesc_PropTest is EOracleDescPropTest {
    address STETH = makeAddr("STETH");
    address WSTETH = makeAddr("WSTETH");

    function _deployOracle() internal override returns (address) {
        return address(new WstEthOracle(STETH, WSTETH));
    }
}
