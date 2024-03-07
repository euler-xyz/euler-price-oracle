// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IPyth} from "@pyth/IPyth.sol";
import {PythStructs} from "@pyth/PythStructs.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract PythOracleTest is Test {
    struct FuzzableConfig {
        address base;
        address quote;
        bytes32 feedId;
        uint256 maxStaleness;
        bool inverse;
        uint8 baseDecimals;
        uint8 quoteDecimals;
    }

    address PYTH = makeAddr("PYTH");
    PythOracle oracle;

    function test_Constructor_Integrity(FuzzableConfig memory c) public {
        _deploy(c);

        assertEq(address(oracle.pyth()), PYTH);
        assertEq(oracle.base(), c.base);
        assertEq(oracle.quote(), c.quote);
        assertEq(oracle.feedId(), c.feedId);
        assertEq(oracle.maxStaleness(), c.maxStaleness);
        assertEq(oracle.inverse(), c.inverse);
    }

    function test_GetQuote_Integrity_NegExpo(FuzzableConfig memory c, PythStructs.Price memory p, uint256 inAmount)
        public
    {
        _bound(c);
        c.inverse = false;
        _deploy(c);

        _bound(p);
        int32 exponent = p.expo + int8(c.quoteDecimals) - int8(c.baseDecimals);
        vm.assume(exponent <= 0);
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );

        inAmount = bound(inAmount, 0, type(uint64).max);
        uint256 outAmount = oracle.getQuote(inAmount, c.base, c.quote);
        assertEq(outAmount, inAmount * uint64(p.price) / 10 ** uint32(-exponent));
    }

    function test_GetQuote_Integrity_PosExpo(FuzzableConfig memory c, PythStructs.Price memory p, uint256 inAmount)
        public
    {
        _bound(c);
        c.inverse = false;
        _deploy(c);

        _bound(p);
        int32 exponent = p.expo + int8(c.quoteDecimals) - int8(c.baseDecimals);
        vm.assume(exponent > 0);
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );

        inAmount = bound(inAmount, 0, type(uint64).max);
        uint256 outAmount = oracle.getQuote(inAmount, c.base, c.quote);
        assertEq(outAmount, inAmount * uint64(p.price) * 10 ** uint32(exponent));
    }

    function test_GetQuote_Integrity_NegExpo_Inv(FuzzableConfig memory c, PythStructs.Price memory p, uint256 inAmount)
        public
    {
        _bound(c);
        c.inverse = true;
        _deploy(c);

        _bound(p);
        int32 exponent = p.expo - int8(c.quoteDecimals) + int8(c.baseDecimals);
        vm.assume(exponent <= 0);
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );

        inAmount = bound(inAmount, 0, type(uint64).max);
        uint256 outAmount = oracle.getQuote(inAmount, c.base, c.quote);
        assertEq(outAmount, inAmount * 10 ** uint32(-exponent) / uint64(p.price));
    }

    function test_GetQuote_Integrity_PosExpo_Inv(FuzzableConfig memory c, PythStructs.Price memory p, uint256 inAmount)
        public
    {
        _bound(c);
        c.inverse = true;
        _deploy(c);

        _bound(p);
        int32 exponent = p.expo - int8(c.quoteDecimals) + int8(c.baseDecimals);
        vm.assume(exponent > 0);
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );

        inAmount = bound(inAmount, 0, type(uint64).max);
        uint256 outAmount = oracle.getQuote(inAmount, c.base, c.quote);
        assertEq(outAmount, inAmount / (uint64(p.price) * 10 ** uint32(exponent)));
    }

    function test_GetQuote_RevertsWhen_InvalidBase(FuzzableConfig memory c, uint256 inAmount, address base) public {
        _deploy(c);
        vm.assume(base != c.base);
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, c.quote));
        oracle.getQuote(inAmount, base, c.quote);
    }

    function test_GetQuote_RevertsWhen_InvalidQuote(FuzzableConfig memory c, uint256 inAmount, address quote) public {
        _deploy(c);
        vm.assume(quote != c.quote);
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, c.base, quote));
        oracle.getQuote(inAmount, c.base, quote);
    }

    function test_GetQuote_RevertsWhen_ZeroPrice(FuzzableConfig memory c, uint256 inAmount, PythStructs.Price memory p)
        public
    {
        _deploy(c);
        p.price = 0;
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidPrice.selector, p.price));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_NegativePrice(
        FuzzableConfig memory c,
        PythStructs.Price memory p,
        uint256 inAmount
    ) public {
        _deploy(c);
        _bound(p);
        p.price = int64(bound(p.price, type(int64).min, -1));
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidPrice.selector, p.price));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_ConfidenceIntervalGtMaxPrice(
        FuzzableConfig memory c,
        PythStructs.Price memory p,
        uint256 inAmount
    ) public {
        _deploy(c);
        _bound(p);
        p.conf = uint64(bound(p.conf, uint64(type(int64).max) + 1, type(uint64).max));
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidConfidenceInterval.selector, p.price, p.conf));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_ConfidenceIntervalGtPrice(
        FuzzableConfig memory c,
        PythStructs.Price memory p,
        uint256 inAmount
    ) public {
        _deploy(c);
        _bound(p);
        p.conf = uint64(bound(p.conf, uint64(p.price) + 1, type(uint64).max));
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidConfidenceInterval.selector, p.price, p.conf));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_ExponentTooSmall(
        FuzzableConfig memory c,
        PythStructs.Price memory p,
        uint256 inAmount
    ) public {
        _deploy(c);
        _bound(p);
        p.expo = int32(bound(p.expo, type(int32).min, -17));
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidExponent.selector, p.expo));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_ExponentTooLarge(
        FuzzableConfig memory c,
        PythStructs.Price memory p,
        uint256 inAmount
    ) public {
        _deploy(c);
        _bound(p);
        p.expo = int32(bound(p.expo, 17, type(int32).max));
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidExponent.selector, p.expo));
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_Integrity_NegExpo(FuzzableConfig memory c, PythStructs.Price memory p, uint256 inAmount)
        public
    {
        _bound(c);
        c.inverse = false;
        _deploy(c);

        _bound(p);
        int32 exponent = p.expo + int8(c.quoteDecimals) - int8(c.baseDecimals);
        vm.assume(exponent <= 0);
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );

        inAmount = bound(inAmount, 0, type(uint64).max);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.base, c.quote);
        assertEq(bidOutAmount, inAmount * uint64(p.price) / 10 ** uint32(-exponent));
        assertEq(askOutAmount, inAmount * uint64(p.price) / 10 ** uint32(-exponent));
    }

    function test_GetQuotes_Integrity_PosExpo(FuzzableConfig memory c, PythStructs.Price memory p, uint256 inAmount)
        public
    {
        _bound(c);
        c.inverse = false;
        _deploy(c);

        _bound(p);
        int32 exponent = p.expo + int8(c.quoteDecimals) - int8(c.baseDecimals);
        vm.assume(exponent > 0);
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );

        inAmount = bound(inAmount, 0, type(uint64).max);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.base, c.quote);
        assertEq(bidOutAmount, inAmount * uint64(p.price) * 10 ** uint32(exponent));
        assertEq(askOutAmount, inAmount * uint64(p.price) * 10 ** uint32(exponent));
    }

    function test_GetQuotes_Integrity_NegExpo_Inv(FuzzableConfig memory c, PythStructs.Price memory p, uint256 inAmount)
        public
    {
        _bound(c);
        c.inverse = true;
        _deploy(c);

        _bound(p);
        int32 exponent = p.expo - int8(c.quoteDecimals) + int8(c.baseDecimals);
        vm.assume(exponent <= 0);
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );

        inAmount = bound(inAmount, 0, type(uint64).max);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.base, c.quote);
        assertEq(bidOutAmount, inAmount * 10 ** uint32(-exponent) / uint64(p.price));
        assertEq(askOutAmount, inAmount * 10 ** uint32(-exponent) / uint64(p.price));
    }

    function test_GetQuotes_Integrity_PosExpo_Inv(FuzzableConfig memory c, PythStructs.Price memory p, uint256 inAmount)
        public
    {
        _bound(c);
        c.inverse = true;
        _deploy(c);

        _bound(p);
        int32 exponent = p.expo - int8(c.quoteDecimals) + int8(c.baseDecimals);
        vm.assume(exponent > 0);
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );

        inAmount = bound(inAmount, 0, type(uint64).max);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.base, c.quote);
        assertEq(bidOutAmount, inAmount / (uint64(p.price) * 10 ** uint32(exponent)));
        assertEq(askOutAmount, inAmount / (uint64(p.price) * 10 ** uint32(exponent)));
    }

    function test_GetQuotes_RevertsWhen_InvalidBase(FuzzableConfig memory c, uint256 inAmount, address base) public {
        _deploy(c);
        vm.assume(base != c.base);
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, c.quote));
        oracle.getQuotes(inAmount, base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidQuote(FuzzableConfig memory c, uint256 inAmount, address quote) public {
        _deploy(c);
        vm.assume(quote != c.quote);
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, c.base, quote));
        oracle.getQuotes(inAmount, c.base, quote);
    }

    function test_GetQuotes_RevertsWhen_ZeroPrice(FuzzableConfig memory c, uint256 inAmount, PythStructs.Price memory p)
        public
    {
        _deploy(c);
        p.price = 0;
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidPrice.selector, p.price));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_NegativePrice(
        FuzzableConfig memory c,
        uint256 inAmount,
        PythStructs.Price memory p
    ) public {
        _deploy(c);
        _bound(p);
        p.price = int64(bound(p.price, type(int64).min, -1));
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidPrice.selector, p.price));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_ConfidenceIntervalGtMaxPrice(
        FuzzableConfig memory c,
        uint256 inAmount,
        PythStructs.Price memory p
    ) public {
        _deploy(c);
        _bound(p);
        p.conf = uint64(bound(p.conf, uint64(type(int64).max) + 1, type(uint64).max));
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidConfidenceInterval.selector, p.price, p.conf));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_ConfidenceIntervalGtPrice(
        FuzzableConfig memory c,
        uint256 inAmount,
        PythStructs.Price memory p
    ) public {
        _deploy(c);
        _bound(p);
        p.conf = uint64(bound(p.conf, uint64(p.price) + 1, type(uint64).max));
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidConfidenceInterval.selector, p.price, p.conf));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_ExponentTooSmall(
        FuzzableConfig memory c,
        uint256 inAmount,
        PythStructs.Price memory p
    ) public {
        _deploy(c);
        _bound(p);
        p.expo = int32(bound(p.expo, type(int32).min, -17));
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidExponent.selector, p.expo));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_ExponentTooLarge(
        FuzzableConfig memory c,
        uint256 inAmount,
        PythStructs.Price memory p
    ) public {
        _deploy(c);
        _bound(p);
        p.expo = int32(bound(p.expo, 17, type(int32).max));
        vm.mockCall(
            PYTH, abi.encodeWithSelector(IPyth.getPriceNoOlderThan.selector, c.feedId, c.maxStaleness), abi.encode(p)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Pyth_InvalidExponent.selector, p.expo));
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_UpdatePrice_Integrity(address caller, bytes[] calldata updateData, uint256 value) public {
        vm.skip(true);
        caller = boundAddr(caller);
        vm.deal(caller, value);
        vm.mockCall(PYTH, value, abi.encodeWithSelector(IPyth.updatePriceFeeds.selector), "");
        vm.prank(caller);
        oracle.updatePrice{value: value}(updateData);
        assertEq(caller.balance, 0);
        assertEq(address(oracle).balance, 0);
        assertEq(PYTH.balance, value);
    }

    function _deploy(FuzzableConfig memory c) private {
        _bound(c);
        vm.mockCall(c.base, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.baseDecimals));
        vm.mockCall(c.quote, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.quoteDecimals));
        oracle = new PythOracle(PYTH, c.base, c.quote, c.feedId, c.maxStaleness, c.inverse);
    }

    function _bound(PythStructs.Price memory p) private pure {
        p.price = int64(bound(p.price, 1, type(int64).max));
        p.conf = uint64(bound(p.conf, 0, uint64(p.price) / 20));
        p.expo = int32(bound(p.expo, -16, 16));
    }

    function _bound(FuzzableConfig memory c) private pure {
        c.base = boundAddr(c.base);
        c.quote = boundAddr(c.quote);
        vm.assume(c.base != c.quote);
        c.baseDecimals = uint8(bound(c.baseDecimals, 0, 18));
        c.quoteDecimals = uint8(bound(c.quoteDecimals, 0, 18));
        c.maxStaleness = uint32(bound(c.maxStaleness, 0, type(uint32).max));
    }
}
