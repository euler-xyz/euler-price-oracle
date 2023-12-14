// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleGovPropTest} from "test/prop/EOracleGov.prop.t.sol";
import {GovernedUniswapV3Oracle} from "src/adapter/uniswap/GovernedUniswapV3Oracle.sol";

contract GovernedUniswapV3OracleGov_PropTest is EOracleGovPropTest {
    address FACTORY = makeAddr("FACTORY");

    function _deployOracle() internal override returns (address) {
        return address(new GovernedUniswapV3Oracle(FACTORY));
    }
}
