// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {HourglassOracleHelper} from "test/adapter/hourglass/HourglassOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {HourglassOracle} from "src/adapter/hourglass/HourglassOracle.sol";

contract HourglassOracleTest is HourglassOracleHelper {
    function test_Constructor_Integrity_Hourglass(FuzzableState memory s) public {
        setUpState(s);
        assertEq(HourglassOracle(oracle).name(), "HourglassOracle");
        assertEq(HourglassOracle(oracle).base(), s.base);
        assertEq(HourglassOracle(oracle).quote(), s.quote);
        assertEq(HourglassOracle(oracle).discountRate(), s.discountRate);
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
        HourglassOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        HourglassOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
    }

    function test_Quotes_Integrity(FuzzableState memory s) public {
        setUpState(s);
        uint256 outAmount = HourglassOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        (uint256 bidOutAmount, uint256 askOutAmount) = HourglassOracle(oracle).getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
        uint256 outAmountInv = HourglassOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        (uint256 bidOutAmountInv, uint256 askOutAmountInv) = HourglassOracle(oracle).getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmountInv, outAmountInv);
        assertEq(askOutAmountInv, outAmountInv);
    }
}
