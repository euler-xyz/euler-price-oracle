// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC4626OracleHelper} from "test/adapter/erc4626/ERC4626OracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {ERC4626Oracle} from "src/adapter/erc4626/ERC4626Oracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract ERC4626OracleTest is ERC4626OracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        setUpState(s);
        assertEq(ERC4626Oracle(oracle).name(), "ERC4626Oracle");
        assertEq(ERC4626Oracle(oracle).base(), s.base);
        assertEq(ERC4626Oracle(oracle).quote(), s.quote);
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
        ERC4626Oracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        ERC4626Oracle(oracle).getQuote(s.inAmount, s.quote, s.base);
    }

    function test_Quotes_Integrity(FuzzableState memory s) public {
        setUpState(s);
        uint256 outAmount = ERC4626Oracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        (uint256 bidOutAmount, uint256 askOutAmount) = ERC4626Oracle(oracle).getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
        uint256 outAmountInv = ERC4626Oracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        (uint256 bidOutAmountInv, uint256 askOutAmountInv) =
            ERC4626Oracle(oracle).getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmountInv, outAmountInv);
        assertEq(askOutAmountInv, outAmountInv);
    }
}
