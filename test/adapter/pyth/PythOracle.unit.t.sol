// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {PythOracleHelper} from "test/adapter/pyth/PythOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract PythOracleTest is PythOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        setUpState(s);

        assertEq(address(PythOracle(oracle).pyth()), PYTH);
        assertEq(PythOracle(oracle).base(), s.base);
        assertEq(PythOracle(oracle).quote(), s.quote);
        assertEq(PythOracle(oracle).feedId(), s.feedId);
        assertEq(PythOracle(oracle).maxStaleness(), s.maxStaleness);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        setUpState(s);
        otherA = boundAddr(otherA);
        otherB = boundAddr(otherB);
        vm.assume(otherA != s.base && otherA != s.quote);
        vm.assume(otherB != s.base && otherB != s.quote);
        expectNotSupported(s.inAmount, s.base, s.base);
        expectNotSupported(s.inAmount, s.quote, s.quote);
        expectNotSupported(s.inAmount, s.base, otherA);
        expectNotSupported(s.inAmount, otherA, s.base);
        expectNotSupported(s.inAmount, s.quote, otherA);
        expectNotSupported(s.inAmount, otherA, s.quote);
        expectNotSupported(s.inAmount, otherA, otherA);
        expectNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_RevertsWhen_NegativePrice(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReturnsNegativePrice, true);
        setUpState(s);

        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s.inAmount, s.base, s.quote, err);
    }

    function test_Quote_RevertsWhen_ConfidenceIntervalGtMaxPrice(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReturnsConfTooWide, true);
        setUpState(s);

        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s.inAmount, s.base, s.quote, err);
    }

    function test_Quote_RevertsWhen_ExponentTooLow(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReturnsExpoTooLow, true);
        setUpState(s);

        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s.inAmount, s.base, s.quote, err);
    }

    function test_Quote_RevertsWhen_ExponentTooHigh(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReturnsExpoTooHigh, true);
        setUpState(s);

        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s.inAmount, s.base, s.quote, err);
    }

    function test_Quote_Integrity(FuzzableState memory s) public {
        setUpState(s);

        uint256 expectedOutAmount = calcOutAmount(s);
        uint256 outAmount = PythOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = PythOracle(oracle).getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Integrity_Inverse(FuzzableState memory s) public {
        setUpState(s);

        uint256 expectedOutAmount = calcOutAmountInverse(s);
        uint256 outAmount = PythOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = PythOracle(oracle).getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_UpdatePrice_Integrity(
        FuzzableState memory s,
        address caller,
        bytes[] calldata updateData,
        uint256 value
    ) public {
        setUpState(s);
        caller = boundAddr(caller);
        vm.deal(caller, value);

        vm.prank(caller);
        PythOracle(oracle).updatePrice{value: value}(updateData);
        assertEq(caller.balance, 0);
    }

    function test_UpdatePrice_RevertsWhen_PythCallReverts(
        FuzzableState memory s,
        address caller,
        bytes[] calldata updateData,
        uint256 value
    ) public {
        setBehavior(Behavior.FeedReverts, true);
        setUpState(s);
        caller = boundAddr(caller);
        vm.deal(caller, value);

        vm.expectRevert();
        vm.prank(caller);
        PythOracle(oracle).updatePrice{value: value}(updateData);
        assertEq(caller.balance, value);
        assertEq(address(PythOracle(oracle)).balance, 0);
    }
}
