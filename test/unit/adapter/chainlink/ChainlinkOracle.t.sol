// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {AggregatorV3Interface} from "src/adapter/chainlink/AggregatorV3Interface.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract ChainlinkOracleTest is Test {
    struct FuzzableConfig {
        address base;
        address quote;
        address feed;
        uint256 maxStaleness;
        uint256 maxDuration;
        bool inverse;
        uint8 baseDecimals;
        uint8 quoteDecimals;
    }

    struct FuzzableRoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    ChainlinkOracle oracle;

    function test_GetQuote_RevertsWhen_AggregatorV3Reverts(FuzzableConfig memory c, uint256 inAmount) public {
        _deploy(c);

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.mockCallRevert(c.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), "oops");
        vm.expectRevert(abi.encodeWithSelector(Errors.Chainlink_CallReverted.selector, "oops"));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_ZeroPrice(FuzzableConfig memory c, FuzzableRoundData memory d, uint256 inAmount)
        public
    {
        _deploy(c);
        _prepareValidRoundData(d);
        d.answer = 0;

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.mockCall(c.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(d));
        vm.expectRevert(abi.encodeWithSelector(Errors.Chainlink_InvalidAnswer.selector, 0));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_NegativePrice(
        FuzzableConfig memory c,
        FuzzableRoundData memory d,
        uint256 inAmount,
        int256 chainlinkAnswer
    ) public {
        _deploy(c);
        _prepareValidRoundData(d);
        chainlinkAnswer = bound(chainlinkAnswer, type(int256).min, -1);
        d.answer = chainlinkAnswer;

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));
        vm.mockCall(c.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(d));
        vm.expectRevert(abi.encodeWithSelector(Errors.Chainlink_InvalidAnswer.selector, chainlinkAnswer));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_RoundIncomplete(
        FuzzableConfig memory c,
        FuzzableRoundData memory d,
        uint256 inAmount
    ) public {
        _deploy(c);
        _prepareValidRoundData(d);
        d.updatedAt = 0;

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.mockCall(c.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(d));
        vm.expectRevert(abi.encodeWithSelector(Errors.Chainlink_RoundIncomplete.selector));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_RoundTooLong(
        FuzzableConfig memory c,
        FuzzableRoundData memory d,
        uint256 inAmount
    ) public {
        _deploy(c);
        _prepareValidRoundData(d);
        vm.assume(d.updatedAt > d.startedAt && d.updatedAt - d.startedAt > c.maxDuration);

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.mockCall(c.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(d));
        vm.expectRevert(
            abi.encodeWithSelector(Errors.Chainlink_RoundTooLong.selector, d.updatedAt - d.startedAt, c.maxDuration)
        );
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_TooStale(
        FuzzableConfig memory c,
        FuzzableRoundData memory d,
        uint256 inAmount,
        uint256 timestamp
    ) public {
        _deploy(c);
        _prepareValidRoundData(d);
        vm.assume(d.updatedAt > d.startedAt && d.updatedAt - d.startedAt <= c.maxDuration);
        vm.assume(timestamp > d.updatedAt && timestamp - d.updatedAt > c.maxStaleness);

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.warp(timestamp);
        vm.mockCall(c.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(d));
        vm.expectRevert(
            abi.encodeWithSelector(Errors.EOracle_TooStale.selector, timestamp - d.updatedAt, c.maxStaleness)
        );
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_Integrity_CallFeed(FuzzableConfig memory c, uint256 inAmount) public {
        _deploy(c);
        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.warp(8);
        vm.mockCall(
            c.feed,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(0), int256(1), uint256(8), uint256(8), uint80(0))
        );
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_NotSupported_Base(FuzzableConfig memory c, address base, uint256 inAmount)
        public
    {
        _deploy(c);
        vm.assume(base != c.base);

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, c.quote));
        oracle.getQuotes(inAmount, base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_NotSupported_Quote(FuzzableConfig memory c, address quote, uint256 inAmount)
        public
    {
        _deploy(c);
        vm.assume(quote != c.quote);

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, c.base, quote));
        oracle.getQuotes(inAmount, c.base, quote);
    }

    function test_GetQuotes_Integrity(FuzzableConfig memory c, uint256 inAmount) public {
        _deploy(c);
        inAmount = bound(inAmount, 1, uint256(type(uint128).max));
        vm.warp(8);
        vm.mockCall(
            c.feed,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(0), int256(1), uint256(8), uint256(8), uint80(0))
        );
        uint256 outAmount = oracle.getQuote(inAmount, c.base, c.quote);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.base, c.quote);

        assertEq(outAmount, bidOutAmount);
        assertEq(bidOutAmount, askOutAmount);
        assertEq(askOutAmount, outAmount);
    }

    function test_Description(FuzzableConfig memory c) public {
        _deploy(c);
        OracleDescription.Description memory desc = oracle.description();
        assertEq(uint8(desc.algorithm), uint8(OracleDescription.Algorithm.VWAP));
        assertEq(uint8(desc.authority), uint8(OracleDescription.Authority.IMMUTABLE));
        assertEq(uint8(desc.paymentModel), uint8(OracleDescription.PaymentModel.FREE));
        assertEq(uint8(desc.requestModel), uint8(OracleDescription.RequestModel.PUSH));
        assertEq(uint8(desc.variant), uint8(OracleDescription.Variant.ADAPTER));
        assertEq(desc.configuration.maxStaleness, c.maxStaleness);
        assertEq(desc.configuration.governor, address(0));
        assertEq(desc.configuration.supportsBidAskSpread, false);
    }

    function _deploy(FuzzableConfig memory c) private {
        c.base = boundAddr(c.base);
        c.quote = boundAddr(c.quote);
        c.feed = boundAddr(c.feed);
        vm.assume(c.base != c.quote && c.quote != c.feed && c.base != c.feed);

        c.baseDecimals = uint8(bound(c.baseDecimals, 0, 24));
        c.quoteDecimals = uint8(bound(c.quoteDecimals, 0, 24));

        vm.mockCall(c.base, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.baseDecimals));
        vm.mockCall(c.quote, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.quoteDecimals));

        oracle = new ChainlinkOracle(c.base, c.quote, c.feed, c.maxStaleness, c.maxDuration, c.inverse);
    }

    function _prepareValidRoundData(FuzzableRoundData memory d) private pure {
        d.answer = bound(d.answer, 1, int256(type(int128).max));
    }
}
