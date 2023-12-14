// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleGovPropTest} from "test/prop/EOracleGov.prop.t.sol";
import {WstEthOracle} from "src/adapter/lido/WstEthOracle.sol";

contract WstEthOracleGov_PropTest is EOracleGovPropTest {
    address STETH = makeAddr("STETH");
    address WSTETH = makeAddr("WSTETH");

    function _deployOracle() internal override returns (address) {
        return address(new WstEthOracle(STETH, WSTETH));
    }
}
