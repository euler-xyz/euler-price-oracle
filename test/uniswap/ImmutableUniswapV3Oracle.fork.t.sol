// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {UNISWAP_V3_FACTORY, USDC, WETH} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {ImmutableUniswapV3Oracle} from "src/uniswap/ImmutableUniswapV3Oracle.sol";

contract ImmutableUniswapV3OracleForkTest is ForkTest {
    ImmutableUniswapV3Oracle oracle;

    function setUp() public {
        _setUpFork();

        oracle = new ImmutableUniswapV3Oracle(UNISWAP_V3_FACTORY);
    }

    function test_UpdateConfig() public {
        oracle.updateConfig(USDC, WETH);
        (address pool, uint32 validUntil, uint24 twapWindow, uint24 fee, uint8 token0Decimals, uint8 token1Decimals) =
            oracle.configs(USDC, WETH);

        assertEq(
            pool,
            oracle.uniswapV3Factory().getPool(USDC, WETH, 500),
            "Should choose the most liquid pool (USDC/WETH 0.05%)"
        );
        assertEq(fee, 500, "Should choose the most liquid pool (USDC/WETH 0.05%)");
        assertEq(token0Decimals, 6);
        assertEq(token1Decimals, 18);
    }
}
