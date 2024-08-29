// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {RateProviderOracleHelper} from "test/adapter/rate/RateProviderOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {RateProviderOracle} from "src/adapter/rate/RateProviderOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract RateProviderOracleTest is RateProviderOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        setUpState(s);
        assertEq(RateProviderOracle(oracle).name(), "RateProviderOracle");
        assertEq(RateProviderOracle(oracle).base(), s.base);
        assertEq(RateProviderOracle(oracle).quote(), s.quote);
        assertEq(RateProviderOracle(oracle).rateProvider(), s.rateProvider);
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

    function test_Quote_RevertsWhen_RateProviderCallReverts(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReverts, true);
        setUpState(s);
        expectRevertForAllQuotePermutations(s.inAmount, s.base, s.quote, "");
    }

    function test_Quote_RevertsWhen_RateProviderReturnsZero(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReturnsZeroPrice, true);
        setUpState(s);
        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s.inAmount, s.base, s.quote, err);
    }

    function test_Quote_Integrity(FuzzableState memory s) public {
        setUpState(s);
        RateProviderOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        RateProviderOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
    }

    function test_Quotes_Integrity(FuzzableState memory s) public {
        setUpState(s);
        uint256 outAmount = RateProviderOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        (uint256 bidOutAmount, uint256 askOutAmount) = RateProviderOracle(oracle).getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
        uint256 outAmountInv = RateProviderOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        (uint256 bidOutAmountInv, uint256 askOutAmountInv) =
            RateProviderOracle(oracle).getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmountInv, outAmountInv);
        assertEq(askOutAmountInv, outAmountInv);
    }
}
