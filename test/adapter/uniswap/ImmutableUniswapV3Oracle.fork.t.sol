// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {UNISWAP_V3_FACTORY, USDC, WETH} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {ImmutableUniswapV3Oracle} from "src/adapter/uniswap/ImmutableUniswapV3Oracle.sol";
import {UniswapV3Config} from "src/adapter/uniswap/UniswapV3Config.sol";
import {UniswapV3Oracle} from "src/adapter/uniswap/UniswapV3Oracle.sol";

contract ImmutableUniswapV3OracleForkTest is ForkTest {
    ImmutableUniswapV3Oracle oracle;

    function setUp() public {
        _setUpFork();

        oracle = new ImmutableUniswapV3Oracle(UNISWAP_V3_FACTORY, new UniswapV3Oracle.ConfigParams[](0));
    }

    function test_UpdateConfig() public {
        oracle.updateConfig(USDC, WETH);
        UniswapV3Config config = oracle.configs(USDC, WETH);

        // assertEq(
        //     config.getPool(),
        //     oracle.uniswapV3Factory().getPool(USDC, WETH, 500),
        //     "Should choose the most liquid pool (USDC/WETH 0.05%)"
        // );
        assertEq(config.getFee(), 500, "Should choose the most liquid pool (USDC/WETH 0.05%)");
        // assertEq(config.getToken0Decimals(), 6);
        // assertEq(config.getToken1Decimals(), 18);
    }
}
