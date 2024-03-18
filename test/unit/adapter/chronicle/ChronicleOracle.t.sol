// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {IChronicle} from "src/adapter/chronicle/IChronicle.sol";
import {ChronicleOracle} from "src/adapter/chronicle/ChronicleOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract ChronicleOracleTest is Test {
    struct FuzzableConfig {
        address base;
        address quote;
        address feed;
        uint256 maxStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        uint8 feedDecimals;
    }

    struct FuzzableAnswer {
        uint256 value;
        uint256 age;
    }

    ChronicleOracle oracle;

    function test_Constructor_Integrity(FuzzableConfig memory c) public {
        _deploy(c);
        assertEq(oracle.base(), c.base);
        assertEq(oracle.quote(), c.quote);
        assertEq(oracle.feed(), c.feed);
        assertEq(oracle.maxStaleness(), c.maxStaleness);
    }

    function test_GetQuote_RevertsWhen_NotSupported_Base(FuzzableConfig memory c, address base, uint256 inAmount)
        public
    {
        _deploy(c);
        vm.assume(base != c.base);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, c.quote));
        oracle.getQuote(inAmount, base, c.quote);
    }

    function test_GetQuote_RevertsWhen_NotSupported_Quote(FuzzableConfig memory c, address quote, uint256 inAmount)
        public
    {
        _deploy(c);
        vm.assume(quote != c.quote);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, c.base, quote));
        oracle.getQuote(inAmount, c.base, quote);
    }

    function test_GetQuote_RevertsWhen_ChronicleReverts(FuzzableConfig memory c, uint256 inAmount) public {
        _deploy(c);

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCallRevert(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), "oops");
        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_ZeroPrice(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount)
        public
    {
        _deploy(c);
        _prepareValidAnswer(d);
        d.value = 0;

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_TooStale(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount)
        public
    {
        _deploy(c);
        _prepareValidAnswer(d);
        vm.assume(d.age > c.maxStaleness);

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, d.age, c.maxStaleness));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_Integrity(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount) public {
        _deploy(c);
        _prepareValidAnswer(d);
        vm.assume(d.age <= c.maxStaleness);
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        uint256 outAmount = oracle.getQuote(inAmount, c.base, c.quote);
        uint256 expectedOutAmount =
            (inAmount * uint256(d.value) * 10 ** c.quoteDecimals) / 10 ** (c.feedDecimals + c.baseDecimals);
        assertEq(outAmount, expectedOutAmount);
    }

    function test_GetQuote_Integrity_Inverse(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount)
        public
    {
        _deploy(c);
        _prepareValidAnswer(d);
        vm.assume(d.age <= c.maxStaleness);
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        uint256 outAmount = oracle.getQuote(inAmount, c.quote, c.base);
        uint256 expectedOutAmount =
            (inAmount * 10 ** (c.feedDecimals + c.baseDecimals)) / (uint256(d.value) * 10 ** c.quoteDecimals);
        assertEq(outAmount, expectedOutAmount);
    }

    function test_GetQuotes_RevertsWhen_NotSupported_Base(FuzzableConfig memory c, address base, uint256 inAmount)
        public
    {
        _deploy(c);
        vm.assume(base != c.base);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, c.quote));
        oracle.getQuotes(inAmount, base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_NotSupported_Quote(FuzzableConfig memory c, address quote, uint256 inAmount)
        public
    {
        _deploy(c);
        vm.assume(quote != c.quote);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, c.base, quote));
        oracle.getQuotes(inAmount, c.base, quote);
    }

    function test_GetQuotes_RevertsWhen_ChronicleReverts(FuzzableConfig memory c, uint256 inAmount) public {
        _deploy(c);

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCallRevert(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), "oops");
        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_ZeroPrice(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount)
        public
    {
        _deploy(c);
        _prepareValidAnswer(d);
        d.value = 0;

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_TooStale(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount)
        public
    {
        _deploy(c);
        _prepareValidAnswer(d);
        vm.assume(d.age > c.maxStaleness);

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, d.age, c.maxStaleness));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_Integrity(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount) public {
        _deploy(c);
        _prepareValidAnswer(d);
        vm.assume(d.age <= c.maxStaleness);
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.base, c.quote);
        uint256 expectedOutAmount =
            (inAmount * uint256(d.value) * 10 ** c.quoteDecimals) / 10 ** (c.feedDecimals + c.baseDecimals);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_GetQuotes_Integrity_Inverse(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount)
        public
    {
        _deploy(c);
        _prepareValidAnswer(d);
        vm.assume(d.age <= c.maxStaleness);
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.quote, c.base);
        uint256 expectedOutAmount =
            (inAmount * 10 ** (c.feedDecimals + c.baseDecimals)) / (uint256(d.value) * 10 ** c.quoteDecimals);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function _deploy(FuzzableConfig memory c) private {
        c.base = boundAddr(c.base);
        c.quote = boundAddr(c.quote);
        c.feed = boundAddr(c.feed);
        vm.assume(c.base != c.quote && c.quote != c.feed && c.base != c.feed);

        c.maxStaleness = bound(c.maxStaleness, 0, type(uint128).max);

        c.baseDecimals = uint8(bound(c.baseDecimals, 2, 18));
        c.quoteDecimals = uint8(bound(c.quoteDecimals, 2, 18));
        c.feedDecimals = uint8(bound(c.feedDecimals, 2, 18));

        vm.mockCall(c.base, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.baseDecimals));
        vm.mockCall(c.quote, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.quoteDecimals));
        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.decimals.selector), abi.encode(c.feedDecimals));

        oracle = new ChronicleOracle(c.base, c.quote, c.feed, c.maxStaleness);
    }

    function _prepareValidAnswer(FuzzableAnswer memory d) private pure {
        d.value = bound(d.value, 1, (type(uint64).max));
        d.age = bound(d.age, 0, type(uint128).max);
    }
}
