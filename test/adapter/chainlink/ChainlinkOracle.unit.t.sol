// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {ChainlinkOracleHelper} from "test/adapter/chainlink/ChainlinkOracleHelper.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract ChainlinkOracleTest is ChainlinkOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);
        assertEq(oracle.base(), s.base);
        assertEq(oracle.quote(), s.quote);
        assertEq(oracle.feed(), s.feed);
        assertEq(oracle.maxStaleness(), s.maxStaleness);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        _deployAndPrepare(s);
        vm.assume(otherA != s.base && otherA != s.quote);
        vm.assume(otherB != s.base && otherB != s.quote);
        assertNotSupported(s.inAmount, s.base, s.base);
        assertNotSupported(s.inAmount, s.quote, s.quote);
        assertNotSupported(s.inAmount, s.base, otherA);
        assertNotSupported(s.inAmount, otherA, s.base);
        assertNotSupported(s.inAmount, s.quote, otherA);
        assertNotSupported(s.inAmount, otherA, s.quote);
        assertNotSupported(s.inAmount, otherA, otherA);
        assertNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_RevertsWhen_AggregatorV3Reverts(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReverts, true);
        _deployAndPrepare(s);

        bytes memory err = abi.encodePacked("oops");
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_RevertsWhen_ZeroPrice(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReturnsZero, true);
        _deployAndPrepare(s);

        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_RevertsWhen_NegativePrice(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReturnsNegative, true);
        _deployAndPrepare(s);

        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector);
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_RevertsWhen_TooStale(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReturnsStalePrice, true);
        _deployAndPrepare(s);

        bytes memory err =
            abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, s.timestamp - s.updatedAt, s.maxStaleness);
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);

        uint256 expectedOutAmount = FixedPointMathLib.fullMulDiv(
            s.inAmount, uint256(s.answer) * 10 ** s.quoteDecimals, 10 ** (s.feedDecimals + s.baseDecimals)
        );
        uint256 outAmount = oracle.getQuote(s.inAmount, s.base, s.quote);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Integrity_Inverse(FuzzableState memory s) public {
        _deployAndPrepare(s);

        uint256 expectedOutAmount = FixedPointMathLib.fullMulDiv(
            s.inAmount, 10 ** (s.feedDecimals + s.baseDecimals), (uint256(s.answer) * 10 ** s.quoteDecimals)
        );

        uint256 outAmount = oracle.getQuote(s.inAmount, s.quote, s.base);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function assertNotSupported(uint256 inAmount, address tokenA, address tokenB) internal {
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, tokenA, tokenB));
        oracle.getQuote(inAmount, tokenA, tokenB);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, tokenA, tokenB));
        oracle.getQuotes(inAmount, tokenA, tokenB);
    }
}
