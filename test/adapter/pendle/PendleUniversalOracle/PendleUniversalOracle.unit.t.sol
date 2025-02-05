// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {PendleUniversalOracleHelper} from "test/adapter/pendle/PendleUniversalOracle/PendleUniversalOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {PendleUniversalOracle} from "src/adapter/pendle/PendleUniversalOracle.sol";

contract PendleUniversalOracleTest is PendleUniversalOracleHelper {
    function test_Constructor_Integrity_Pendle(FuzzableState memory s) public {
        setUpState(s);
        assertEq(PendleUniversalOracle(oracle).name(), "PendleUniversalOracle");
        assertEq(PendleUniversalOracle(oracle).pendleMarket(), s.pendleMarket);
        assertEq(PendleUniversalOracle(oracle).twapWindow(), s.twapWindow);
        assertEq(PendleUniversalOracle(oracle).base(), s.base);
        assertEq(PendleUniversalOracle(oracle).quote(), s.quote);
    }

    function test_Constructor_RevertsWhen_Constructor_BaseNotPt(FuzzableState memory s) public {
        setBehavior(Behavior.Constructor_BaseNotPt, true);
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
        PendleUniversalOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        PendleUniversalOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
    }

    function test_Quotes_Integrity(FuzzableState memory s) public {
        setUpState(s);
        uint256 outAmount = PendleUniversalOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        (uint256 bidOutAmount, uint256 askOutAmount) =
            PendleUniversalOracle(oracle).getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
        uint256 outAmountInv = PendleUniversalOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        (uint256 bidOutAmountInv, uint256 askOutAmountInv) =
            PendleUniversalOracle(oracle).getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmountInv, outAmountInv);
        assertEq(askOutAmountInv, outAmountInv);
    }
}
