// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {RedstoneCoreOracleHelper} from "test/adapter/redstone/RedstoneCoreOracleHelper.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract RedstoneCoreOracleTest is RedstoneCoreOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        setUpState(s);

        assertEq(RedstoneCoreOracle(oracle).base(), s.base);
        assertEq(RedstoneCoreOracle(oracle).quote(), s.quote);
        assertEq(RedstoneCoreOracle(oracle).feedId(), s.feedId);
        assertEq(RedstoneCoreOracle(oracle).maxStaleness(), s.maxStaleness);
        assertEq(RedstoneCoreOracle(oracle).lastPrice(), 0);
        assertEq(RedstoneCoreOracle(oracle).lastUpdatedAt(), 0);
    }

    function test_Constructor_RevertsWhen_MaxStalenessLt3Min(FuzzableState memory s) public {
        setBehavior(Behavior.Constructor_MaxStalenessTooSmall, true);
        vm.expectRevert();
        setUpState(s);
    }

    function test_UpdatePrice_Integrity(FuzzableState memory s) public {
        setUpState(s);
        _mockPrice(s);
        _updatePrice(s);

        assertEq(RedstoneCoreOracle(oracle).lastPrice(), s.price);
        assertEq(RedstoneCoreOracle(oracle).lastUpdatedAt(), s.tsUpdatePrice);
    }

    function test_UpdatePrice_Overflow(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReturnsTooLargePrice, true);
        setUpState(s);
        _mockPrice(s);

        vm.expectRevert(Errors.PriceOracle_Overflow.selector);
        _updatePrice(s);

        assertEq(RedstoneCoreOracle(oracle).lastPrice(), 0);
        assertEq(RedstoneCoreOracle(oracle).lastUpdatedAt(), 0);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        setUpState(s);
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
        _mockPrice(s);
        _updatePrice(s);

        uint256 expectedOutAmount = (s.inAmount * s.price * 10 ** s.quoteDecimals) / 10 ** (8 + s.baseDecimals);

        uint256 outAmount = RedstoneCoreOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = RedstoneCoreOracle(oracle).getQuotes(s.inAmount, s.base, s.quote);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Inverse_Integrity(FuzzableState memory s) public {
        setUpState(s);
        _mockPrice(s);
        _updatePrice(s);

        uint256 expectedOutAmount = (s.inAmount * 10 ** (8 + s.baseDecimals)) / (s.price * 10 ** s.quoteDecimals);

        uint256 outAmount = RedstoneCoreOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = RedstoneCoreOracle(oracle).getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_RevertsWhen_TooStale(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReturnsStalePrice, true);
        setUpState(s);
        _mockPrice(s);
        _updatePrice(s);

        bytes memory err =
            abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, s.tsGetQuote - s.tsUpdatePrice, s.maxStaleness);
        expectRevertForAllQuotePermutations(s.inAmount, s.base, s.quote, err);
    }
}
