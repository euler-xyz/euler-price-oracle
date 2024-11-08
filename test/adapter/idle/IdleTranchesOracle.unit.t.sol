// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IdleTranchesOracleHelper} from "test/adapter/idle/IdleTranchesOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {IdleTranchesOracle} from "src/adapter/idle/IdleTranchesOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract IdleTranchesOracleTest is IdleTranchesOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        setUpState(s);
        assertEq(IdleTranchesOracle(oracle).name(), "IdleTranchesOracle");
        assertEq(IdleTranchesOracle(oracle).cdo(), s.cdo);
        assertEq(IdleTranchesOracle(oracle).tranche(), s.tranche);
        assertEq(IdleTranchesOracle(oracle).underlying(), s.underlying);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        setUpState(s);
        otherA = boundAddr(otherA);
        otherB = boundAddr(otherB);
        vm.assume(otherA != s.tranche && otherA != s.underlying);
        vm.assume(otherB != s.tranche && otherB != s.underlying);
        expectNotSupported(s.inAmount, s.tranche, s.tranche);
        expectNotSupported(s.inAmount, s.underlying, s.underlying);
        expectNotSupported(s.inAmount, s.tranche, otherA);
        expectNotSupported(s.inAmount, otherA, s.tranche);
        expectNotSupported(s.inAmount, s.underlying, otherA);
        expectNotSupported(s.inAmount, otherA, s.underlying);
        expectNotSupported(s.inAmount, otherA, otherA);
        expectNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_RevertsWhen_IdleCDOCallReverts(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReverts, true);
        setUpState(s);
        expectRevertForAllQuotePermutations(s.inAmount, s.tranche, s.underlying, "");
    }

    function test_Quote_RevertsWhen_IdleCDOReturnsZero(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReturnsZeroPrice, true);
        setUpState(s);
        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s.inAmount, s.tranche, s.underlying, err);
    }

    function test_Quote_Integrity(FuzzableState memory s) public {
        setUpState(s);
        IdleTranchesOracle(oracle).getQuote(s.inAmount, s.tranche, s.underlying);
        IdleTranchesOracle(oracle).getQuote(s.inAmount, s.underlying, s.tranche);
    }

    function test_Quotes_Integrity(FuzzableState memory s) public {
        setUpState(s);
        uint256 outAmount = IdleTranchesOracle(oracle).getQuote(s.inAmount, s.tranche, s.underlying);
        (uint256 bidOutAmount, uint256 askOutAmount) =
            IdleTranchesOracle(oracle).getQuotes(s.inAmount, s.tranche, s.underlying);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
        uint256 outAmountInv = IdleTranchesOracle(oracle).getQuote(s.inAmount, s.underlying, s.tranche);
        (uint256 bidOutAmountInv, uint256 askOutAmountInv) =
            IdleTranchesOracle(oracle).getQuotes(s.inAmount, s.underlying, s.tranche);
        assertEq(bidOutAmountInv, outAmountInv);
        assertEq(askOutAmountInv, outAmountInv);
    }
}
