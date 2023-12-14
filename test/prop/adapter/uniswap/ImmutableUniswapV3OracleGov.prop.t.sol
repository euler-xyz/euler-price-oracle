// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleGovPropTest} from "test/prop/EOracleGov.prop.t.sol";
import {ImmutableUniswapV3Oracle} from "src/adapter/uniswap/ImmutableUniswapV3Oracle.sol";

contract ImmutableUniswapV3OracleGov_PropTest is EOracleGovPropTest {
    address FACTORY = makeAddr("FACTORY");

    function _deployOracle() internal override returns (address) {
        return address(new ImmutableUniswapV3Oracle(FACTORY));
    }
}
