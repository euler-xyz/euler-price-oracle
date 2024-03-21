// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {RedstoneCoreOracleHelper} from "test/adapter/redstone/RedstoneCoreOracleHelper.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract RedstoneCoreOracleTest is RedstoneCoreOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);

        assertEq(oracle.base(), s.base);
        assertEq(oracle.quote(), s.quote);
        assertEq(oracle.feedId(), s.feedId);
        assertEq(oracle.maxStaleness(), s.maxStaleness);
        assertEq(oracle.lastPrice(), 0);
        assertEq(oracle.lastUpdatedAt(), 0);
    }

    function test_Constructor_RevertsWhen_MaxStalenessLt3Min(FuzzableState memory s) public {
        _setBehavior(Behavior.MaxStalenessTooSmall, true);
        vm.expectRevert();
        _deployAndPrepare(s);
    }

    function test_UpdatePrice_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);
        _mockPrice(s);
        _updatePrice(s);

        assertEq(oracle.lastPrice(), s.price);
        assertEq(oracle.lastUpdatedAt(), s.tsUpdatePrice);
    }

    function test_UpdatePrice_Overflow(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReturnsTooLargePrice, true);
        _deployAndPrepare(s);
        _mockPrice(s);

        vm.expectRevert(Errors.PriceOracle_Overflow.selector);
        _updatePrice(s);

        assertEq(oracle.lastPrice(), 0);
        assertEq(oracle.lastUpdatedAt(), 0);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        _deployAndPrepare(s);
        vm.assume(otherA != s.base && otherA != s.quote);
        vm.assume(otherB != s.base && otherB != s.quote);
        assertNotSupported(s.inAmount, s.base, s.base);
        assertNotSupported(s.inAmount, s.quote, s.quote);
        assertNotSupported(s.inAmount, s.base, otherA);
        assertNotSupported(s.inAmount, otherA, s.base);
        assertNotSupported(s.inAmount, s.quote, otherA);
        assertNotSupported(s.inAmount, otherA, s.quote);
        assertNotSupported(s.inAmount, otherA, otherA);
        assertNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);
        _mockPrice(s);
        _updatePrice(s);

        uint256 expectedOutAmount = (s.inAmount * s.price * 10 ** s.quoteDecimals) / 10 ** (8 + s.baseDecimals);

        uint256 outAmount = oracle.getQuote(s.inAmount, s.base, s.quote);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Inverse_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);
        _mockPrice(s);
        _updatePrice(s);

        uint256 expectedOutAmount = (s.inAmount * 10 ** (8 + s.baseDecimals)) / (s.price * 10 ** s.quoteDecimals);

        uint256 outAmount = oracle.getQuote(s.inAmount, s.quote, s.base);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_RevertsWhen_TooStale(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReturnsStalePrice, true);
        _deployAndPrepare(s);
        _mockPrice(s);
        _updatePrice(s);

        bytes memory err =
            abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, s.tsGetQuote - s.tsUpdatePrice, s.maxStaleness);
        expectRevertForAllQuotePermutations(s, err);
    }

    function assertNotSupported(uint256 inAmount, address tokenA, address tokenB) internal {
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, tokenA, tokenB));
        oracle.getQuote(inAmount, tokenA, tokenB);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, tokenA, tokenB));
        oracle.getQuotes(inAmount, tokenA, tokenB);
    }
}
