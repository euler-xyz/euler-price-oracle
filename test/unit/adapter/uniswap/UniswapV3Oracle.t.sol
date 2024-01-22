// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
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
    }

    UniswapV3Oracle oracle;

    function test_Constructor_Integrity(FuzzableConfig memory c) public {
        _deploy(c);
    }

    function test_GetQuote_RevertsWhen_InAmountGtUint128(FuzzableConfig memory c, uint256 inAmount) public {
        _deploy(c);
        inAmount = bound(inAmount, uint256(type(uint128).max) + 1, type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_Overflow.selector));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_NotSupported_Base(FuzzableConfig memory c, uint256 inAmount, address base)
        public
    {
        _deploy(c);
        vm.assume(base != c.base);
        inAmount = bound(inAmount, 0, uint256(type(uint128).max));
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, c.quote));
        oracle.getQuote(inAmount, base, c.quote);
    }

    function test_GetQuote_RevertsWhen_NotSupported_Quote(FuzzableConfig memory c, uint256 inAmount, address quote)
        public
    {
        _deploy(c);
        vm.assume(quote != c.quote);
        inAmount = bound(inAmount, 0, uint256(type(uint128).max));
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, c.base, quote));
        oracle.getQuote(inAmount, c.base, quote);
    }

    function test_GetQuotes_RevertsWhen_InAmountGtUint128(FuzzableConfig memory c, uint256 inAmount) public {
        _deploy(c);
        inAmount = bound(inAmount, uint256(type(uint128).max) + 1, type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_Overflow.selector));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_NotSupported_Base(FuzzableConfig memory c, uint256 inAmount, address base)
        public
    {
        _deploy(c);
        vm.assume(base != c.base);
        inAmount = bound(inAmount, 0, uint256(type(uint128).max));
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, c.quote));
        oracle.getQuotes(inAmount, base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_NotSupported_Quote(FuzzableConfig memory c, uint256 inAmount, address quote)
        public
    {
        _deploy(c);
        vm.assume(quote != c.quote);
        inAmount = bound(inAmount, 0, uint256(type(uint128).max));
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, c.base, quote));
        oracle.getQuotes(inAmount, c.base, quote);
    }

    function _deploy(FuzzableConfig memory c) private {
        c.base = boundAddr(c.base);
        c.quote = boundAddr(c.quote);
        c.uniswapV3Factory = boundAddr(c.uniswapV3Factory);
        vm.assume(c.base != c.quote && c.quote != c.uniswapV3Factory && c.uniswapV3Factory != c.base);
        vm.assume(c.twapWindow != 0);

        oracle = new UniswapV3Oracle(c.base, c.quote, c.fee, c.twapWindow, c.uniswapV3Factory);
    }
}
