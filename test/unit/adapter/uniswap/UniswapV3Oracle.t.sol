// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IUniswapV3PoolActions} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol";
import {IUniswapV3PoolState} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol";
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
        assertEq(oracle.uniswapV3Factory(), c.uniswapV3Factory);
        assertEq(oracle.fee(), c.fee);
        assertEq(oracle.twapWindow(), c.twapWindow);
    }

    function test_Constructor_RevertsWhen_TwapWindowTooLong(FuzzableConfig memory c) public {
        _bound(c);
        c.twapWindow = uint32(bound(c.twapWindow, 786421, type(uint32).max));
        vm.expectRevert(abi.encodeWithSelector(Errors.UniswapV3_TwapWindowTooLong.selector, c.twapWindow, 786420));
        _deploy(c);
    }

    function test_GetQuote_Integrity_Spot(FuzzableConfig memory c, uint256 inAmount) public {
        _bound(c);
        c.twapWindow = 0;
        _deploy(c);
        inAmount = bound(inAmount, 1, type(uint128).max);
        uint256 outAmount = oracle.getQuote(inAmount, c.base, c.quote);
        assertEq(outAmount, OracleLibrary.getQuoteAtTick(c.slot0.tick, uint128(inAmount), c.base, c.quote));
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

    function test_GetQuotes_Integrity_Spot(FuzzableConfig memory c, uint256 inAmount) public {
        _bound(c);
        c.twapWindow = 0;
        _deploy(c);
        inAmount = bound(inAmount, 0, type(uint128).max);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.base, c.quote);
        assertEq(bidOutAmount, OracleLibrary.getQuoteAtTick(c.slot0.tick, uint128(inAmount), c.base, c.quote));
        assertEq(askOutAmount, OracleLibrary.getQuoteAtTick(c.slot0.tick, uint128(inAmount), c.base, c.quote));
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
        vm.assume(c.base != c.quote && c.quote != c.uniswapV3Factory && c.uniswapV3Factory != c.base);
        c.twapWindow = uint32(bound(c.twapWindow, 0, 9 days));
        c.slot0.tick = int24(bound(c.slot0.tick, TickMath.MIN_TICK, TickMath.MAX_TICK));
        c.slot0.observationCardinalityNext =
            uint16(bound(c.slot0.observationCardinalityNext, c.slot0.observationCardinality, type(uint16).max));
    }

    function _deploy(FuzzableConfig memory c) private {
        (address token0, address token1) = c.base < c.quote ? (c.base, c.quote) : (c.quote, c.base);
        bytes32 poolKey = keccak256(abi.encode(token0, token1, c.fee));
        bytes32 create2Hash = keccak256(
            abi.encodePacked(
                hex"ff",
                c.uniswapV3Factory,
                poolKey,
                bytes32(0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54)
            )
        );
        address pool = address(uint160(uint256(create2Hash)));

        vm.mockCall(pool, abi.encodeWithSelector(IUniswapV3PoolState.slot0.selector), abi.encode(c.slot0));
        vm.mockCall(pool, abi.encodeWithSelector(IUniswapV3PoolActions.increaseObservationCardinalityNext.selector), "");

        oracle = new UniswapV3Oracle(c.base, c.quote, c.fee, c.twapWindow, c.uniswapV3Factory);
    }
}
