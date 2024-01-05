// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleDescPropTest} from "test/prop/EOracleDesc.prop.t.sol";
import {GovernedUniswapV3Oracle} from "src/adapter/uniswap/GovernedUniswapV3Oracle.sol";

contract GovernedUniswapV3OracleDesc_PropTest is EOracleDescPropTest {
    address FACTORY = makeAddr("FACTORY");

    function _deployOracle() internal override returns (address) {
        return address(new GovernedUniswapV3Oracle(FACTORY));
    }
}
