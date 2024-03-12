// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {RedstoneCoreOracleHarness} from "test/utils/RedstoneCoreOracleHarness.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract RedstoneCoreOracleTest is Test {
    struct FuzzableConfig {
        address base;
        address quote;
        bytes32 feedId;
        uint32 maxStaleness;
        bool inverse;
        uint8 baseDecimals;
        uint8 quoteDecimals;
    }

    RedstoneCoreOracleHarness oracle;

    function test_Constructor_Integrity(FuzzableConfig memory c) public {
        _deploy(c);

        assertEq(oracle.base(), c.base);
        assertEq(oracle.quote(), c.quote);
        assertEq(oracle.feedId(), c.feedId);
        assertEq(oracle.maxStaleness(), c.maxStaleness);
        assertEq(oracle.inverse(), c.inverse);
        assertEq(oracle.lastPrice(), 0);
        assertEq(oracle.lastUpdatedAt(), 0);
    }

    function test_Constructor_RevertsWhen_MaxStalenessLt3Min(FuzzableConfig memory c) public {
        c.base = boundAddr(c.base);
        c.quote = boundAddr(c.quote);
        vm.assume(c.base != c.quote);

        c.baseDecimals = uint8(bound(c.baseDecimals, 0, 24));
        c.quoteDecimals = uint8(bound(c.quoteDecimals, 0, 24));
        c.maxStaleness = uint32(bound(c.maxStaleness, 0, 3 minutes - 1));

        vm.mockCall(c.base, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.baseDecimals));
        vm.mockCall(c.quote, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.quoteDecimals));

        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new RedstoneCoreOracleHarness(c.base, c.quote, c.feedId, c.maxStaleness, c.inverse);
    }

    function test_UpdatePrice_Integrity(FuzzableConfig memory c, uint256 timestamp, uint256 price) public {
        _deploy(c);
        timestamp = bound(timestamp, c.maxStaleness + 1, type(uint32).max);
        price = bound(price, 0, type(uint224).max);

        vm.warp(timestamp);

        oracle.setPrice(price);
        oracle.updatePrice();

        assertEq(oracle.lastPrice(), price);
        assertEq(oracle.lastUpdatedAt(), timestamp);
    }

    function test_UpdatePrice_Overflow(FuzzableConfig memory c, uint256 timestamp, uint256 price) public {
        _deploy(c);
        timestamp = bound(timestamp, c.maxStaleness + 1, type(uint32).max);
        price = bound(price, uint256(type(uint224).max) + 1, type(uint256).max);

        vm.warp(timestamp);

        oracle.setPrice(price);
        vm.expectRevert(Errors.PriceOracle_Overflow.selector);
        oracle.updatePrice();

        assertEq(oracle.lastPrice(), 0);
        assertEq(oracle.lastUpdatedAt(), 0);
    }

    function test_GetQuote_Integrity(
        FuzzableConfig memory c,
        uint256 tsUpdatePrice,
        uint256 tsGetQuote,
        uint256 inAmount,
        uint256 price
    ) public {
        _deploy(c);
        inAmount = bound(inAmount, 0, type(uint128).max);
        price = bound(price, 1, type(uint128).max);
        tsUpdatePrice = bound(tsUpdatePrice, c.maxStaleness + 1, type(uint32).max - c.maxStaleness);
        tsGetQuote = bound(tsGetQuote, tsUpdatePrice, tsUpdatePrice + c.maxStaleness);

        vm.warp(tsUpdatePrice);
        oracle.setPrice(price);
        oracle.updatePrice();

        vm.warp(tsGetQuote);
        uint256 outAmount = oracle.getQuote(inAmount, c.base, c.quote);
        uint256 expectedOutAmount =
            c.inverse ? (inAmount * 10 ** c.quoteDecimals) / price : (inAmount * price) / 10 ** c.baseDecimals;
        assertEq(outAmount, expectedOutAmount);
    }

    function test_GetQuote_RevertsWhen_InvalidBase(FuzzableConfig memory c, uint256 inAmount, address base) public {
        _deploy(c);
        vm.assume(base != c.base);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, c.quote));
        oracle.getQuote(inAmount, base, c.quote);
    }

    function test_GetQuote_RevertsWhen_InvalidQuote(FuzzableConfig memory c, uint256 inAmount, address quote) public {
        _deploy(c);
        vm.assume(quote != c.quote);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, c.base, quote));
        oracle.getQuote(inAmount, c.base, quote);
    }

    function test_GetQuote_RevertsWhen_TooStale(
        FuzzableConfig memory c,
        uint256 tsUpdatePrice,
        uint256 tsGetQuote,
        uint256 inAmount,
        uint256 price
    ) public {
        _deploy(c);
        inAmount = bound(inAmount, 0, type(uint128).max);
        price = bound(price, 1, type(uint128).max);
        tsUpdatePrice = bound(tsUpdatePrice, c.maxStaleness + 1, type(uint32).max - c.maxStaleness - 1);
        tsGetQuote = bound(tsGetQuote, tsUpdatePrice + c.maxStaleness + 1, type(uint32).max);

        vm.warp(tsUpdatePrice);
        oracle.setPrice(price);
        oracle.updatePrice();

        vm.warp(tsGetQuote);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, tsGetQuote - tsUpdatePrice, c.maxStaleness)
        );
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_Integrity(
        FuzzableConfig memory c,
        uint256 tsUpdatePrice,
        uint256 tsGetQuote,
        uint256 inAmount,
        uint256 price
    ) public {
        _deploy(c);
        inAmount = bound(inAmount, 0, type(uint128).max);
        price = bound(price, 1, type(uint128).max);
        tsUpdatePrice = bound(tsUpdatePrice, c.maxStaleness + 1, type(uint32).max - c.maxStaleness);
        tsGetQuote = bound(tsGetQuote, tsUpdatePrice, tsUpdatePrice + c.maxStaleness);

        vm.warp(tsUpdatePrice);
        oracle.setPrice(price);
        oracle.updatePrice();

        vm.warp(tsGetQuote);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.base, c.quote);
        uint256 expectedOutAmount =
            c.inverse ? (inAmount * 10 ** c.quoteDecimals) / price : (inAmount * price) / 10 ** c.baseDecimals;
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_GetQuotes_RevertsWhen_InvalidBase(FuzzableConfig memory c, uint256 inAmount, address base) public {
        _deploy(c);
        vm.assume(base != c.base);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, c.quote));
        oracle.getQuotes(inAmount, base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidQuote(FuzzableConfig memory c, uint256 inAmount, address quote) public {
        _deploy(c);
        vm.assume(quote != c.quote);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, c.base, quote));
        oracle.getQuotes(inAmount, c.base, quote);
    }

    function test_GetQuotes_RevertsWhen_TooStale(
        FuzzableConfig memory c,
        uint256 tsUpdatePrice,
        uint256 tsGetQuote,
        uint256 inAmount,
        uint256 price
    ) public {
        _deploy(c);
        inAmount = bound(inAmount, 0, type(uint128).max);
        price = bound(price, 1, type(uint128).max);
        tsUpdatePrice = bound(tsUpdatePrice, c.maxStaleness + 1, type(uint32).max - c.maxStaleness - 1);
        tsGetQuote = bound(tsGetQuote, tsUpdatePrice + c.maxStaleness + 1, type(uint32).max);

        vm.warp(tsUpdatePrice);
        oracle.setPrice(price);
        oracle.updatePrice();

        vm.warp(tsGetQuote);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, tsGetQuote - tsUpdatePrice, c.maxStaleness)
        );
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function _deploy(FuzzableConfig memory c) private {
        c.base = boundAddr(c.base);
        c.quote = boundAddr(c.quote);
        vm.assume(c.base != c.quote);

        c.baseDecimals = uint8(bound(c.baseDecimals, 0, 24));
        c.quoteDecimals = uint8(bound(c.quoteDecimals, 0, 24));
        c.maxStaleness = uint32(bound(c.maxStaleness, 3 minutes, 24 hours));

        vm.mockCall(c.base, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.baseDecimals));
        vm.mockCall(c.quote, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.quoteDecimals));

        oracle = new RedstoneCoreOracleHarness(c.base, c.quote, c.feedId, c.maxStaleness, c.inverse);
    }
}
