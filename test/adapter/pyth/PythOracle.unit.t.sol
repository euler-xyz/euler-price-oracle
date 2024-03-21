// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {PythOracleHelper} from "test/adapter/pyth/PythOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";
import {StubPyth} from "test/adapter/pyth/StubPyth.sol";
import {Errors} from "src/lib/Errors.sol";

contract PythOracleTest is PythOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);

        assertEq(address(oracle.pyth()), PYTH);
        assertEq(oracle.base(), s.base);
        assertEq(oracle.quote(), s.quote);
        assertEq(oracle.feedId(), s.feedId);
        assertEq(oracle.maxStaleness(), s.maxStaleness);
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

    function test_Quote_RevertsWhen_ZeroPrice(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReturnsZero, true);
        _deployAndPrepare(s);

        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_RevertsWhen_NegativePrice(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReturnsNegative, true);
        _deployAndPrepare(s);

        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_RevertsWhen_ConfidenceIntervalGtMaxPrice(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReturnsConfTooWide, true);
        _deployAndPrepare(s);

        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_RevertsWhen_ExponentTooLow(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReturnsExpoTooLow, true);
        _deployAndPrepare(s);

        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_RevertsWhen_ExponentTooHigh(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReturnsExpoTooHigh, true);
        _deployAndPrepare(s);

        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);

        uint256 expectedOutAmount;
        int8 diff = int8(s.baseDecimals) - int8(s.p.expo);
        if (diff > 0) {
            expectedOutAmount = FixedPointMathLib.fullMulDiv(
                s.inAmount, uint256(uint64(s.p.price)) * 10 ** s.quoteDecimals, 10 ** (uint8(diff))
            );
        } else {
            expectedOutAmount = FixedPointMathLib.fullMulDiv(
                s.inAmount, uint256(uint64(s.p.price)) * 10 ** (s.quoteDecimals + uint8(-diff)), 1
            );
        }
        uint256 outAmount = oracle.getQuote(s.inAmount, s.base, s.quote);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Integrity_Inverse(FuzzableState memory s) public {
        _deployAndPrepare(s);

        uint256 expectedOutAmount;
        int8 diff = int8(s.baseDecimals) - int8(s.p.expo);
        if (diff > 0) {
            expectedOutAmount = FixedPointMathLib.fullMulDiv(
                s.inAmount, 10 ** uint8(diff), uint256(uint64(s.p.price)) * 10 ** s.quoteDecimals
            );
        } else {
            expectedOutAmount = FixedPointMathLib.fullMulDiv(
                s.inAmount, 1, uint256(uint64(s.p.price)) * 10 ** (s.quoteDecimals + uint8(-diff))
            );
        }
        uint256 outAmount = oracle.getQuote(s.inAmount, s.quote, s.base);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_UpdatePrice_Integrity(
        FuzzableState memory s,
        address caller,
        bytes[] calldata updateData,
        uint256 value
    ) public {
        _deployAndPrepare(s);
        caller = boundAddr(caller);
        vm.deal(caller, value);

        vm.prank(caller);
        oracle.updatePrice{value: value}(updateData);
        assertEq(caller.balance, 0);
    }

    function test_UpdatePrice_RevertsWhen_PythCallReverts(
        FuzzableState memory s,
        address caller,
        bytes[] calldata updateData,
        uint256 value
    ) public {
        _setBehavior(Behavior.FeedReverts, true);
        _deployAndPrepare(s);
        caller = boundAddr(caller);
        vm.deal(caller, value);

        vm.expectRevert();
        vm.prank(caller);
        oracle.updatePrice{value: value}(updateData);
        assertEq(caller.balance, value);
        assertEq(address(oracle).balance, 0);
    }

    function assertNotSupported(uint256 inAmount, address tokenA, address tokenB) internal {
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, tokenA, tokenB));
        oracle.getQuote(inAmount, tokenA, tokenB);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, tokenA, tokenB));
        oracle.getQuotes(inAmount, tokenA, tokenB);
    }
}
