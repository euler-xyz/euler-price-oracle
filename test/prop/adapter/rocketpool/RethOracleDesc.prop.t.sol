// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleDescPropTest} from "test/prop/EOracleDesc.prop.t.sol";
import {RethOracle} from "src/adapter/rocketpool/RethOracle.sol";

contract RethOracleDesc_PropTest is EOracleDescPropTest {
    address WETH = makeAddr("WETH");
    address RETH = makeAddr("RETH");

    function _deployOracle() internal override returns (address) {
        return address(new RethOracle(WETH, WETH));
    }
}
