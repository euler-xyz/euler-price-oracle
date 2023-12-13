// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {UniswapV3Config, UniswapV3ConfigLib} from "src/adapter/uniswap/UniswapV3Config.sol";

contract UniswapV3ConfigTest is Test {
    function test_From(
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

    function test_Integrity_Bijective(UniswapV3Config configA, UniswapV3Config configB) public {
        bool eqPool = configA.getPool() == configB.getPool();
        bool eqValidUntil = configA.getValidUntil() == configB.getValidUntil();
        bool eqTwapWindow = configA.getTwapWindow() == configB.getTwapWindow();
        bool eqFee = configA.getFee() == configB.getFee();
        bool eqToken0Decimals = configA.getToken0Decimals() == configB.getToken0Decimals();
        bool eqToken1Decimals = configA.getToken1Decimals() == configB.getToken1Decimals();

        bool eqComponents = eqPool && eqValidUntil && eqTwapWindow && eqFee && eqToken0Decimals && eqToken1Decimals;
        bool eqConfig = UniswapV3Config.unwrap(configA) == UniswapV3Config.unwrap(configB);

        assertEq(eqConfig, eqComponents);
    }

    function test_Empty() public {
        UniswapV3Config config = UniswapV3ConfigLib.empty();
        assertEq(config.getPool(), address(0));
        assertEq(config.getValidUntil(), 0);
        assertEq(config.getTwapWindow(), 0);
        assertEq(config.getFee(), 0);
        assertEq(config.getToken0Decimals(), 0);
        assertEq(config.getToken1Decimals(), 0);
    }

    function test_IsEmpty_TrueForEmpty() public {
        UniswapV3Config config = UniswapV3ConfigLib.empty();
        assertTrue(config.isEmpty());
    }

    function test_IsEmpty_TrueForZero() public {
        UniswapV3Config config = UniswapV3Config.wrap(0);
        assertTrue(config.isEmpty());
    }

    function test_IsEmpty_FalseForNonZero(uint256 _underlying) public {
        vm.assume(_underlying != 0);
        UniswapV3Config config = UniswapV3Config.wrap(_underlying);
        assertFalse(config.isEmpty());
    }
}
