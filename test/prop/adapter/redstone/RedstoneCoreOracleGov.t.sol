// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleGovPropTest} from "test/prop/EOracleGov.prop.t.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";

contract RedstoneCoreOracleGov_PropTest is EOracleGovPropTest {
    function _deployOracle() internal override returns (address) {
        return address(new RedstoneCoreOracle());
    }
}
