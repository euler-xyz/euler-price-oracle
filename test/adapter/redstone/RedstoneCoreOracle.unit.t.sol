// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {RedstoneCoreOracleHelper} from "test/adapter/redstone/RedstoneCoreOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract RedstoneCoreOracleTest is RedstoneCoreOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        setUpState(s);

        assertEq(RedstoneCoreOracle(oracle).base(), s.base);
        assertEq(RedstoneCoreOracle(oracle).quote(), s.quote);
        assertEq(RedstoneCoreOracle(oracle).feedId(), s.feedId);
        assertEq(RedstoneCoreOracle(oracle).maxStaleness(), s.maxStaleness);
    }

    function test_Constructor_RevertsWhen_MaxStalenessLt3Min(FuzzableState memory s) public {
        setBehavior(Behavior.Constructor_MaxStalenessTooSmall, true);
        vm.expectRevert();
        setUpState(s);
    }

    function test_UpdatePrice_Integrity(FuzzableState memory s) public {
        setUpState(s);
        mockPrice(s);
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
        mockPrice(s);

        uint256 expectedOutAmount = calcOutAmount(s);

        uint256 outAmount = RedstoneCoreOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = RedstoneCoreOracle(oracle).getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Inverse_Integrity(FuzzableState memory s) public {
        setUpState(s);
        mockPrice(s);

        uint256 expectedOutAmount = calcOutAmountInverse(s);

        uint256 outAmount = RedstoneCoreOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = RedstoneCoreOracle(oracle).getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_RevertsWhen_TooStale(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReturnsStalePrice, true);
        setUpState(s);
        mockPrice(s);

        bytes memory err =
            abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, s.tsGetQuote - s.tsUpdatePrice, s.maxStaleness);
        expectRevertForAllQuotePermutations(s.inAmount, s.base, s.quote, err);
    }
}
