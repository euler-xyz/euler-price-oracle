// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {UniswapV3OracleHarness} from "test/utils/UniswapV3OracleHarness.sol";
import {MockERC20} from "test/utils/MockERC20.sol";
import {UniswapV3Config, UniswapV3ConfigLib} from "src/adapter/uniswap/UniswapV3Config.sol";
import {UniswapV3Oracle} from "src/adapter/uniswap/UniswapV3Oracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract UniswapV3OracleTest is Test {
    address constant UNISWAP_V3_FACTORY = address(0x3333);
    UniswapV3OracleHarness oracle;

    function setUp() public {
        oracle = new UniswapV3OracleHarness(UNISWAP_V3_FACTORY);
    }

    function test_Constructor_Integrity() public {
        assertEq(address(oracle.uniswapV3Factory()), UNISWAP_V3_FACTORY);
    }

    function test_GetQuote_RevertsWhenInAmountGtUint128(
        UniswapV3Oracle.ConfigParams memory params,
        uint256 inAmount,
        uint256 timestamp,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) public {
        vm.assume(params.validUntil != type(uint256).max && params.validUntil != 0);
        timestamp = bound(timestamp, 0, uint256(params.validUntil));
        vm.assume(params.twapWindow != 0);

        params.token0 = boundAddr(params.token0);
        params.token1 = boundAddr(params.token1);
        vm.assume(params.token0 < params.token1);

        vm.mockCall(params.token0, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token0Decimals));
        vm.mockCall(params.token1, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token1Decimals));

        oracle.setConfig(params);
        vm.warp(timestamp);

        inAmount = bound(inAmount, uint256(type(uint128).max) + 1, type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_Overflow.selector));
        oracle.getQuote(inAmount, params.token0, params.token1);
    }

    function test_GetConfig_InitallyEmpty(address base, address quote) public {
        UniswapV3Config config = oracle.getConfig(base, quote);
        assertTrue(config.isEmpty());
    }

    function test_GetConfigOrRevert_RevertsWhen_NoConfig(address base, address quote) public {
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getConfigOrRevert(base, quote);
    }

    function test_GetConfigOrRevert_RevertsWhen_ExpiredConfig(
        UniswapV3Oracle.ConfigParams memory params,
        uint256 timestamp,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) public {
        vm.assume(params.validUntil != type(uint256).max && params.validUntil != 0);
        timestamp = bound(timestamp, uint256(params.validUntil) + 1, type(uint256).max);
        vm.assume(params.twapWindow != 0);

        params.token0 = boundAddr(params.token0);
        params.token1 = boundAddr(params.token1);
        vm.assume(params.token0 < params.token1);

        vm.mockCall(params.token0, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token0Decimals));
        vm.mockCall(params.token1, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token1Decimals));

        oracle.setConfig(params);
        vm.warp(timestamp);
        vm.expectRevert(abi.encodeWithSelector(Errors.ConfigExpired.selector, params.token0, params.token1));
        oracle.getConfigOrRevert(params.token0, params.token1);
    }

    function test_GetConfigOrRevert_Integrity_ReturnsNonExpiredConfig(
        UniswapV3Oracle.ConfigParams memory params,
        uint256 timestamp,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) public {
        vm.assume(params.validUntil != type(uint256).max && params.validUntil != 0);
        timestamp = bound(timestamp, 0, uint256(params.validUntil));
        vm.assume(params.twapWindow != 0);

        params.token0 = boundAddr(params.token0);
        params.token1 = boundAddr(params.token1);
        vm.assume(params.token0 < params.token1);

        vm.mockCall(params.token0, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token0Decimals));
        vm.mockCall(params.token1, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token1Decimals));

        oracle.setConfig(params);

        vm.warp(timestamp);
        UniswapV3Config storedConfig = oracle.getConfigOrRevert(params.token0, params.token1);
        assertEq(storedConfig.getPool(), params.pool);
        assertEq(storedConfig.getValidUntil(), params.validUntil);
        assertEq(storedConfig.getFee(), params.fee);
        assertEq(storedConfig.getTwapWindow(), params.twapWindow);
        assertEq(storedConfig.getToken0Decimals(), token0Decimals);
        assertEq(storedConfig.getToken1Decimals(), token1Decimals);
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
        vm.assume(twapWindow != 0);

        UniswapV3Config expectedConfig =
            UniswapV3ConfigLib.from(pool, validUntil, twapWindow, fee, token0Decimals, token1Decimals);
        UniswapV3Config returnedConfig = oracle.setConfig(
            UniswapV3Oracle.ConfigParams({
                token0: token0,
                token1: token1,
                pool: pool,
                validUntil: validUntil,
                fee: fee,
                twapWindow: twapWindow
            })
        );
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

    function test_ComputePoolAddress_InvariantOnOrder(address tokenA, address tokenB, uint24 fee) public {
        address poolAB = oracle.computePoolAddress(tokenA, tokenB, fee);
        address poolBA = oracle.computePoolAddress(tokenB, tokenA, fee);

        assertEq(poolAB, poolBA);
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

interface IUniswapV3Pool {
    function observe(uint32[] calldata secondsAgos)
        external
        view
        returns (int56[] memory tickCumulatives, uint160[] memory secondsPerLiquidityCumulativeX128s);
}
