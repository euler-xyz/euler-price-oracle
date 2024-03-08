// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IUniswapV3PoolActions} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol";
import {IUniswapV3PoolState} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {UniswapV3Oracle} from "src/adapter/uniswap/UniswapV3Oracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract UniswapV3OracleTest is Test {
    struct FuzzableConfig {
        address base;
        address quote;
        uint24 fee;
        uint32 twapWindow;
        address uniswapV3Factory;
        address pool;
        FuzzableSlot0 slot0;
    }

    struct FuzzableSlot0 {
        uint160 sqrtPriceX96;
        int24 tick;
        uint16 observationIndex;
        uint16 observationCardinality;
        uint16 observationCardinalityNext;
        uint8 feeProtocol;
        bool unlocked;
    }

    UniswapV3Oracle oracle;

    function test_Constructor_Integrity(FuzzableConfig memory c) public {
        _bound(c);
        _deploy(c);
        assertEq(oracle.token0(), c.base < c.quote ? c.base : c.quote);
        assertEq(oracle.token1(), c.base < c.quote ? c.quote : c.base);
        assertEq(oracle.fee(), c.fee);
        assertEq(oracle.twapWindow(), c.twapWindow);
    }

    function test_Constructor_RevertsWhen_TwapWindowTooShort(FuzzableConfig memory c) public {
        _bound(c);
        c.twapWindow = uint32(bound(c.twapWindow, 0, 59));
        vm.expectRevert(Errors.UniswapV3_InvalidTwapWindow.selector);
        _deploy(c);
    }

    function test_Constructor_RevertsWhen_TwapWindowTooLong(FuzzableConfig memory c) public {
        _bound(c);
        c.twapWindow = uint32(bound(c.twapWindow, 786421, type(uint32).max));
        vm.expectRevert(Errors.UniswapV3_InvalidTwapWindow.selector);
        _deploy(c);
    }

    function test_GetQuote_RevertsWhen_NotSupported_Base(FuzzableConfig memory c, uint256 inAmount, address base)
        public
    {
        _bound(c);
        _deploy(c);
        vm.assume(base != c.base);
        inAmount = bound(inAmount, 0, uint256(type(uint128).max));
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, c.quote));
        oracle.getQuote(inAmount, base, c.quote);
    }

    function test_GetQuote_RevertsWhen_NotSupported_Quote(FuzzableConfig memory c, uint256 inAmount, address quote)
        public
    {
        _bound(c);
        _deploy(c);
        vm.assume(quote != c.quote);
        inAmount = bound(inAmount, 0, uint256(type(uint128).max));
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, c.base, quote));
        oracle.getQuote(inAmount, c.base, quote);
    }

    function test_GetQuote_RevertsWhen_InAmountGtUint128(FuzzableConfig memory c, uint256 inAmount) public {
        _bound(c);
        _deploy(c);
        inAmount = bound(inAmount, uint256(type(uint128).max) + 1, type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_Overflow.selector));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_NotSupported_Base(FuzzableConfig memory c, uint256 inAmount, address base)
        public
    {
        _bound(c);
        _deploy(c);
        vm.assume(base != c.base);
        inAmount = bound(inAmount, 0, uint256(type(uint128).max));
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, c.quote));
        oracle.getQuotes(inAmount, base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_NotSupported_Quote(FuzzableConfig memory c, uint256 inAmount, address quote)
        public
    {
        _bound(c);
        _deploy(c);
        vm.assume(quote != c.quote);
        inAmount = bound(inAmount, 0, uint256(type(uint128).max));
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, c.base, quote));
        oracle.getQuotes(inAmount, c.base, quote);
    }

    function test_GetQuotes_RevertsWhen_InAmountGtUint128(FuzzableConfig memory c, uint256 inAmount) public {
        _bound(c);
        _deploy(c);
        inAmount = bound(inAmount, uint256(type(uint128).max) + 1, type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_Overflow.selector));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function _bound(FuzzableConfig memory c) private pure {
        c.base = boundAddr(c.base);
        c.quote = boundAddr(c.quote);
        c.uniswapV3Factory = boundAddr(c.uniswapV3Factory);
        c.pool = boundAddr(c.pool);
        vm.assume(
            c.base != c.quote && c.base != c.uniswapV3Factory && c.base != c.pool && c.quote != c.uniswapV3Factory
                && c.quote != c.pool && c.uniswapV3Factory != c.pool
        );
        c.twapWindow = uint32(bound(c.twapWindow, 60, 9 days));
        c.slot0.tick = int24(bound(c.slot0.tick, TickMath.MIN_TICK, TickMath.MAX_TICK));
        c.slot0.observationCardinalityNext =
            uint16(bound(c.slot0.observationCardinalityNext, c.slot0.observationCardinality, type(uint16).max));
    }

    function _deploy(FuzzableConfig memory c) private {
        vm.mockCall(
            c.uniswapV3Factory,
            abi.encodeWithSelector(IUniswapV3Factory.getPool.selector, c.base, c.quote, c.fee),
            abi.encode(c.pool)
        );

        vm.mockCall(c.pool, abi.encodeWithSelector(IUniswapV3PoolState.slot0.selector), abi.encode(c.slot0));
        vm.mockCall(
            c.pool, abi.encodeWithSelector(IUniswapV3PoolActions.increaseObservationCardinalityNext.selector), ""
        );

        oracle = new UniswapV3Oracle(c.base, c.quote, c.fee, c.twapWindow, c.uniswapV3Factory);
    }
}
