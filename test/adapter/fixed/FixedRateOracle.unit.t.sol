// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {FixedRateOracleHelper} from "test/adapter/fixed/FixedRateOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {FixedRateOracle} from "src/adapter/fixed/FixedRateOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract FixedRateOracleTest is FixedRateOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        setUpState(s);
        assertEq(FixedRateOracle(oracle).name(), "FixedRateOracle");
        assertEq(FixedRateOracle(oracle).base(), s.base);
        assertEq(FixedRateOracle(oracle).quote(), s.quote);
        assertEq(FixedRateOracle(oracle).rate(), s.rate);
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
        FixedRateOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        FixedRateOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
    }

    function test_Quotes_Integrity(FuzzableState memory s) public {
        setUpState(s);
        uint256 outAmount = FixedRateOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        (uint256 bidOutAmount, uint256 askOutAmount) = FixedRateOracle(oracle).getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
        uint256 outAmountInv = FixedRateOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        (uint256 bidOutAmountInv, uint256 askOutAmountInv) =
            FixedRateOracle(oracle).getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmountInv, outAmountInv);
        assertEq(askOutAmountInv, outAmountInv);
    }
}
