// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {EOracleGovPropTest} from "test/prop/EOracleGov.prop.t.sol";
import {GovernedUniswapV3Oracle} from "src/adapter/uniswap/GovernedUniswapV3Oracle.sol";

contract GovernedUniswapV3OracleGov_PropTest is EOracleGovPropTest {
    address FACTORY = makeAddr("FACTORY");

    function _deployOracle() internal override returns (address) {
        return address(new GovernedUniswapV3Oracle(FACTORY));
    }

    function _govMethods() internal pure override returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = GovernedUniswapV3Oracle.govSetConfig.selector;
        selectors[1] = GovernedUniswapV3Oracle.govUnsetConfig.selector;
        return selectors;
    }
}
