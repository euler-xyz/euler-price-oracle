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
        assertEq(RedstoneCoreOracle(oracle).feedDecimals(), s.feedDecimals);
        assertEq(RedstoneCoreOracle(oracle).maxPriceStaleness(), s.maxPriceStaleness);
        assertEq(RedstoneCoreOracle(oracle).maxCacheStaleness(), s.maxCacheStaleness);
        assertEq(RedstoneCoreOracle(oracle).cachedPrice(), 0);
        assertEq(RedstoneCoreOracle(oracle).cacheUpdatedAt(), 0);
    }

    function test_UpdatePrice_Integrity(FuzzableState memory s) public {
        setUpState(s);
        mockPrice(s);
        setPrice(s);

        assertEq(RedstoneCoreOracle(oracle).cachedPrice(), s.price);
        assertEq(RedstoneCoreOracle(oracle).cacheUpdatedAt(), s.tsUpdatePrice);
    }

    function test_UpdatePrice_Overflow(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReturnsTooLargePrice, true);
        setUpState(s);
        mockPrice(s);

        vm.expectRevert(Errors.PriceOracle_Overflow.selector);
        setPrice(s);

        assertEq(RedstoneCoreOracle(oracle).cachedPrice(), 0);
        assertEq(RedstoneCoreOracle(oracle).cacheUpdatedAt(), 0);
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
        setPrice(s);

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
        setPrice(s);

        uint256 expectedOutAmount = calcOutAmountInverse(s);

        uint256 outAmount = RedstoneCoreOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = RedstoneCoreOracle(oracle).getQuotes(s.inAmount, s.quote, s.base);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_RevertsWhen_PriceTooStale(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReturnsStalePrice, true);
        setUpState(s);
        mockPrice(s);

        bytes memory err = abi.encodeWithSelector(
            Errors.PriceOracle_TooStale.selector, s.tsUpdatePrice - s.tsDataPackage, s.maxPriceStaleness
        );
        vm.expectRevert(err);
        setPrice(s);
    }

    function test_Quote_RevertsWhen_CacheTooStale(FuzzableState memory s) public {
        setBehavior(Behavior.CachedPriceStale, true);
        setUpState(s);
        mockPrice(s);
        setPrice(s);

        bytes memory err = abi.encodeWithSelector(
            Errors.PriceOracle_TooStale.selector, s.tsGetQuote - s.tsUpdatePrice, s.maxCacheStaleness
        );
        expectRevertForAllQuotePermutations(s.inAmount, s.base, s.quote, err);
    }
}
