// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {UniswapV3OracleHarness} from "test/utils/UniswapV3OracleHarness.sol";
import {MockERC20} from "test/utils/MockERC20.sol";
import {UniswapV3Config, UniswapV3ConfigLib} from "src/adapter/uniswap/UniswapV3Config.sol";

contract UniswapV3OracleTest is Test {
    address constant UNISWAP_V3_FACTORY = address(0x3333);
    UniswapV3OracleHarness oracle;

    function setUp() public {
        oracle = new UniswapV3OracleHarness(UNISWAP_V3_FACTORY);
    }

    function test_CanQuote_FalseIf_AmountTooLarge(UniswapV3Config config, uint256 inAmount, address base, address quote)
        public
    {
        inAmount = bound(inAmount, uint256(type(uint128).max) + 1, type(uint256).max);
        (address token0, address token1) = oracle.sortTokens(base, quote);
        oracle.setConfig(token0, token1, config);

        assertFalse(oracle.canQuote(inAmount, base, quote));
    }

    function test_CanQuote_FalseIf_NoConfig(uint256 inAmount, address base, address quote) public {
        assertFalse(oracle.canQuote(inAmount, base, quote));
    }

    function test_CanQuote_FalseIf_Expired(UniswapV3Config config, uint256 inAmount, address base, address quote)
        public
    {
        vm.roll(1e20);
        vm.assume(config.getValidUntil() < block.timestamp);
        (address token0, address token1) = oracle.sortTokens(base, quote);
        oracle.setConfig(token0, token1, config);

        assertFalse(oracle.canQuote(inAmount, base, quote));
    }

    function test_CanQuote_Integrity(UniswapV3Config config, uint256 inAmount, address base, address quote) public {
        vm.roll(1e20);
        vm.assume(config.getValidUntil() >= block.timestamp);
        inAmount = bound(inAmount, 0, uint256(type(uint128).max));
        (address token0, address token1) = oracle.sortTokens(base, quote);
        oracle.setConfig(token0, token1, config);

        assertTrue(oracle.canQuote(inAmount, base, quote));
    }

    function test_GetConfig_InitallyEmpty(address base, address quote) public {
        UniswapV3Config config = oracle.getConfig(base, quote);
        assertTrue(config.isEmpty());
    }

    function test_GetOrRevertConfig_InitallyReverts(address base, address quote) public {
        vm.expectRevert();
        oracle.getOrRevertConfig(base, quote);
    }

    function test_SetConfig_Integrity(
        address pool,
        uint32 validUntil,
        uint24 fee,
        uint24 twapWindow,
        address token0,
        address token1,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) public {
        token0 = boundAddr(token0);
        token1 = boundAddr(token1);
        vm.assume(token0 < token1);
        vm.mockCall(token0, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token0Decimals));
        vm.mockCall(token1, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token1Decimals));

        UniswapV3Config expectedConfig =
            UniswapV3ConfigLib.from(pool, validUntil, twapWindow, fee, token0Decimals, token1Decimals);
        UniswapV3Config returnedConfig = oracle.setConfig(token0, token1, pool, validUntil, fee, twapWindow);
        UniswapV3Config storedConfig = oracle.getConfig(token0, token1);

        assertEq(UniswapV3Config.unwrap(returnedConfig), UniswapV3Config.unwrap(expectedConfig));
        assertEq(UniswapV3Config.unwrap(storedConfig), UniswapV3Config.unwrap(expectedConfig));

        assertEq(storedConfig.getPool(), pool);
        assertEq(storedConfig.getValidUntil(), validUntil);
        assertEq(storedConfig.getFee(), fee);
        assertEq(storedConfig.getTwapWindow(), twapWindow);
        assertEq(storedConfig.getToken0Decimals(), ERC20(token0).decimals());
        assertEq(storedConfig.getToken1Decimals(), ERC20(token1).decimals());
    }

    function test_SortTokens(address tokenA, address tokenB) public {
        (address token0, address token1) = oracle.sortTokens(tokenA, tokenB);

        if (tokenA < tokenB) {
            assertEq(token0, tokenA);
            assertEq(token1, tokenB);
        } else {
            assertEq(token0, tokenB);
            assertEq(token1, tokenA);
        }
    }
}
