// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {ChronicleOracleHelper} from "test/adapter/chronicle/ChronicleOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {IChronicle} from "src/adapter/chronicle/IChronicle.sol";
import {ChronicleOracle} from "src/adapter/chronicle/ChronicleOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract ChronicleOracleTest is ChronicleOracleHelper {
    ChronicleOracle oracle;

    function test_Constructor_Integrity(FuzzableConfig memory c) public {
        oracle = _deploy(c);
        assertEq(oracle.base(), c.base);
        assertEq(oracle.quote(), c.quote);
        assertEq(oracle.feed(), c.feed);
        assertEq(oracle.maxStaleness(), c.maxStaleness);
    }

    function test_GetQuote_RevertsWhen_NotSupported_Base(FuzzableConfig memory c, address base, uint256 inAmount)
        public
    {
        oracle = _deploy(c);
        vm.assume(base != c.base);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, c.quote));
        oracle.getQuote(inAmount, base, c.quote);
    }

    function test_GetQuote_RevertsWhen_NotSupported_Quote(FuzzableConfig memory c, address quote, uint256 inAmount)
        public
    {
        oracle = _deploy(c);
        vm.assume(quote != c.quote);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, c.base, quote));
        oracle.getQuote(inAmount, c.base, quote);
    }

    function test_GetQuote_RevertsWhen_ChronicleReverts(FuzzableConfig memory c, uint256 inAmount) public {
        oracle = _deploy(c);

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCallRevert(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), "oops");
        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_ZeroPrice(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount)
        public
    {
        oracle = _deploy(c);
        _prepareValidAnswer(d, c.maxStaleness);
        d.value = 0;

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_TooStale(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount)
        public
    {
        oracle = _deploy(c);
        _prepareValidAnswer(d, c.maxStaleness);
        d.age = bound(d.age, c.maxStaleness + 1, type(uint256).max);

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, d.age, c.maxStaleness));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_Integrity(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount) public {
        oracle = _deploy(c);
        _prepareValidAnswer(d, c.maxStaleness);
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
        oracle = _deploy(c);
        _prepareValidAnswer(d, c.maxStaleness);
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
        oracle = _deploy(c);
        vm.assume(base != c.base);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, c.quote));
        oracle.getQuotes(inAmount, base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_NotSupported_Quote(FuzzableConfig memory c, address quote, uint256 inAmount)
        public
    {
        oracle = _deploy(c);
        vm.assume(quote != c.quote);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, c.base, quote));
        oracle.getQuotes(inAmount, c.base, quote);
    }

    function test_GetQuotes_RevertsWhen_ChronicleReverts(FuzzableConfig memory c, uint256 inAmount) public {
        oracle = _deploy(c);

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCallRevert(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), "oops");
        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_ZeroPrice(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount)
        public
    {
        oracle = _deploy(c);
        _prepareValidAnswer(d, c.maxStaleness);
        d.value = 0;

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_TooStale(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount)
        public
    {
        oracle = _deploy(c);
        _prepareValidAnswer(d, c.maxStaleness);
        d.age = bound(d.age, c.maxStaleness + 1, type(uint256).max);

        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, d.age, c.maxStaleness));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_Integrity(FuzzableConfig memory c, FuzzableAnswer memory d, uint256 inAmount) public {
        oracle = _deploy(c);
        _prepareValidAnswer(d, c.maxStaleness);
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
        oracle = _deploy(c);
        _prepareValidAnswer(d, c.maxStaleness);
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.quote, c.base);
        uint256 expectedOutAmount =
            (inAmount * 10 ** (c.feedDecimals + c.baseDecimals)) / (uint256(d.value) * 10 ** c.quoteDecimals);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }
}
