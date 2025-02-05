// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PendleOracleHelper} from "test/adapter/pendle/PendleOracle/PendleOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {PendleOracle} from "src/adapter/pendle/PendleOracle.sol";

contract PendleOracleTest is PendleOracleHelper {
    function test_Constructor_Integrity_Pendle(FuzzableState memory s) public {
        setUpState(s);
        assertEq(PendleOracle(oracle).name(), "PendleOracle");
        assertEq(PendleOracle(oracle).pendleMarket(), s.pendleMarket);
        assertEq(PendleOracle(oracle).twapWindow(), s.twapWindow);
        assertEq(PendleOracle(oracle).base(), s.base);
        assertEq(PendleOracle(oracle).quote(), s.quote);
    }

    function test_Constructor_RevertsWhen_Constructor_BaseNotPt(FuzzableState memory s) public {
        setBehavior(Behavior.Constructor_BaseNotPt, true);
        vm.expectRevert();
        setUpState(s);
    }

    function test_Constructor_RevertsWhen_Constructor_QuoteNotSyOrAsset(FuzzableState memory s) public {
        setBehavior(Behavior.Constructor_QuoteNotSyOrAsset, true);
        vm.expectRevert();
        setUpState(s);
    }

    function test_Constructor_RevertsWhen_Constructor_TwapWindowTooShort(FuzzableState memory s) public {
        setBehavior(Behavior.Constructor_TwapWindowTooShort, true);
        vm.expectRevert();
        setUpState(s);
    }

    function test_Constructor_RevertsWhen_Constructor_TwapWindowTooLong(FuzzableState memory s) public {
        setBehavior(Behavior.Constructor_TwapWindowTooLong, true);
        vm.expectRevert();
        setUpState(s);
    }

    function test_Constructor_RevertsWhen_Constructor_CardinalityTooSmall(FuzzableState memory s) public {
        setBehavior(Behavior.Constructor_CardinalityTooSmall, true);
        vm.expectRevert();
        setUpState(s);
    }

    function test_Constructor_RevertsWhen_Constructor_TooFewObservations(FuzzableState memory s) public {
        setBehavior(Behavior.Constructor_CardinalityTooSmall, true);
        vm.expectRevert();
        setUpState(s);
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

    function test_Quote_Integrity(FuzzableState memory s) public {
        setUpState(s);
        PendleOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        PendleOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
    }

    function test_Quotes_Integrity(FuzzableState memory s) public {
        setUpState(s);
        uint256 outAmount = PendleOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        (uint256 bidOutAmount, uint256 askOutAmount) = PendleOracle(oracle).getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
        uint256 outAmountInv = PendleOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        (uint256 bidOutAmountInv, uint256 askOutAmountInv) = PendleOracle(oracle).getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmountInv, outAmountInv);
        assertEq(askOutAmountInv, outAmountInv);
    }
}
