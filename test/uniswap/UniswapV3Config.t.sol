// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import {UniswapV3Config, UniswapV3ConfigLib} from "src/uniswap/UniswapV3Config.sol";

contract UniswapV3ConfigTest is Test {
    function testFuzz_Config(
        address pool,
        uint32 validUntil,
        uint24 twapWindow,
        uint24 fee,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) public {
        UniswapV3Config config =
            UniswapV3ConfigLib.from(pool, validUntil, twapWindow, fee, token0Decimals, token1Decimals);
        assertEq(config.getPool(), pool);
        assertEq(config.getValidUntil(), validUntil);
        assertEq(config.getTwapWindow(), twapWindow);
        assertEq(config.getFee(), fee);
        assertEq(config.getToken0Decimals(), token0Decimals);
        assertEq(config.getToken1Decimals(), token1Decimals);
    }

    function test_ValidUntil() public {
        uint32 validUntil = 999999;
        UniswapV3Config config = UniswapV3ConfigLib.from(address(0), validUntil, 0, 0, 0, 0);
        assertEq(config.getValidUntil(), validUntil);
    }

    function test_Token1Decimals() public {
        UniswapV3Config config = UniswapV3ConfigLib.from(address(0), 0, 0, 0, 0, 18);

        config.__debug_print();
        assertEq(config.getToken1Decimals(), 18);
    }
}
