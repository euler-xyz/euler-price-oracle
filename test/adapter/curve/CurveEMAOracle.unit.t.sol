// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {CurveEMAOracleHelper} from "test/adapter/curve/CurveEMAOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {CurveEMAOracle} from "src/adapter/curve/CurveEMAOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract CurveEMAOracleTest is CurveEMAOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        setUpState(s);
        assertEq(CurveEMAOracle(oracle).pool(), s.pool);
        assertEq(CurveEMAOracle(oracle).base(), s.base);
        assertEq(CurveEMAOracle(oracle).quote(), s.coins_0);
        assertEq(CurveEMAOracle(oracle).priceOracleIndex(), s.priceOracleIndex);
    }

    function test_Constructor_Integrity_LPMode(FuzzableState memory s) public {
        setBehavior(Behavior.Constructor_LpMode, true);
        setUpState(s);
        assertEq(CurveEMAOracle(oracle).pool(), s.pool);
        assertEq(CurveEMAOracle(oracle).base(), s.base);
        assertEq(CurveEMAOracle(oracle).quote(), s.coins_0);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        setUpState(s);
        otherA = boundAddr(otherA);
        otherB = boundAddr(otherB);
        vm.assume(otherA != s.base && otherA != s.coins_0);
        vm.assume(otherB != s.base && otherB != s.coins_0);
        expectNotSupported(s.inAmount, s.base, s.base);
        expectNotSupported(s.inAmount, s.coins_0, s.coins_0);
        expectNotSupported(s.inAmount, s.base, otherA);
        expectNotSupported(s.inAmount, otherA, s.base);
        expectNotSupported(s.inAmount, s.coins_0, otherA);
        expectNotSupported(s.inAmount, otherA, s.coins_0);
        expectNotSupported(s.inAmount, otherA, otherA);
        expectNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_Integrity(FuzzableState memory s) public {
        setUpState(s);

        uint256 expectedOutAmount = calcOutAmount(s);
        uint256 outAmount = CurveEMAOracle(oracle).getQuote(s.inAmount, s.base, s.coins_0);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = CurveEMAOracle(oracle).getQuotes(s.inAmount, s.base, s.coins_0);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Integrity_Inverse(FuzzableState memory s) public {
        setUpState(s);

        uint256 expectedOutAmount = calcOutAmountInverse(s);
        uint256 outAmount = CurveEMAOracle(oracle).getQuote(s.inAmount, s.coins_0, s.base);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = CurveEMAOracle(oracle).getQuotes(s.inAmount, s.coins_0, s.base);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }
}
