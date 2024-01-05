// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleDescPropTest} from "test/prop/EOracleDesc.prop.t.sol";
import {ImmutableUniswapV3Oracle} from "src/adapter/uniswap/ImmutableUniswapV3Oracle.sol";

contract ImmutableUniswapV3OracleDesc_PropTest is EOracleDescPropTest {
    address FACTORY = makeAddr("FACTORY");

    function _deployOracle() internal override returns (address) {
        return address(new ImmutableUniswapV3Oracle(FACTORY));
    }
}
