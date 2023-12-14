// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleGovPropTest} from "test/prop/EOracleGov.prop.t.sol";
import {RethOracle} from "src/adapter/rocketpool/RethOracle.sol";

contract RethOracleGov_PropTest is EOracleGovPropTest {
    address WETH = makeAddr("WETH");
    address RETH = makeAddr("RETH");

    function _deployOracle() internal override returns (address) {
        return address(new RethOracle(WETH, WETH));
    }
}
