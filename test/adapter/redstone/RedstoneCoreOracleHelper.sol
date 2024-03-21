// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {RedstoneCoreOracleHarness} from "test/adapter/redstone/RedstoneCoreOracleHarness.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";

contract RedstoneCoreOracleHelper is Test {
    struct FuzzableState {
        // Config
        address base;
        address quote;
        bytes32 feedId;
        uint32 maxStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        uint8 feedDecimals;
        // Answer
        uint256 price;
        // Environment
        uint256 tsUpdatePrice;
        uint256 tsGetQuote;
        uint256 inAmount;
    }

    enum Behavior {
        MaxStalenessTooSmall,
        FeedReturnsZeroPrice,
        FeedReturnsTooLargePrice,
        FeedReturnsStalePrice
    }

    RedstoneCoreOracleHarness internal oracle;
    mapping(Behavior => bool) private behaviors;

    function _setBehavior(Behavior behavior, bool _status) internal {
        behaviors[behavior] = _status;
    }

    function _deployAndPrepare(FuzzableState memory s) internal {
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);
        vm.assume(s.base != s.quote);

        s.baseDecimals = uint8(bound(s.baseDecimals, 2, 18));
        s.quoteDecimals = uint8(bound(s.quoteDecimals, 2, 18));

        if (behaviors[Behavior.MaxStalenessTooSmall]) {
            s.maxStaleness = uint32(bound(s.maxStaleness, 0, 3 minutes - 1));
        } else {
            s.maxStaleness = uint32(bound(s.maxStaleness, 3 minutes, 24 hours));
        }

        vm.mockCall(s.base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.baseDecimals));
        vm.mockCall(s.quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.quoteDecimals));

        oracle = new RedstoneCoreOracleHarness(s.base, s.quote, s.feedId, s.maxStaleness);

        if (behaviors[Behavior.FeedReturnsZeroPrice]) {
            s.price = 0;
        } else if (behaviors[Behavior.FeedReturnsTooLargePrice]) {
            s.price = bound(s.price, uint256(type(uint208).max) + 1, type(uint256).max);
        } else {
            s.price = bound(s.price, 1, type(uint64).max);
        }

        if (behaviors[Behavior.FeedReturnsStalePrice]) {
            s.tsUpdatePrice = bound(s.tsUpdatePrice, 3 minutes + 1, type(uint48).max - s.maxStaleness - 1);
            s.tsGetQuote = bound(s.tsGetQuote, s.tsUpdatePrice + s.maxStaleness + 1, type(uint48).max);
        } else {
            s.tsUpdatePrice = bound(s.tsUpdatePrice, 3 minutes + 1, type(uint48).max - s.maxStaleness);
            s.tsGetQuote = bound(s.tsGetQuote, s.tsUpdatePrice, s.tsUpdatePrice + s.maxStaleness);
        }

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);
    }

    function _mockPrice(FuzzableState memory s) internal {
        vm.warp(s.tsUpdatePrice);
        oracle.setPrice(s.price);
    }

    function _updatePrice(FuzzableState memory s) internal {
        oracle.updatePrice();
        vm.warp(s.tsGetQuote);
    }

    function expectRevertForAllQuotePermutations(FuzzableState memory s, bytes memory revertData) internal {
        vm.expectRevert(revertData);
        oracle.getQuote(s.inAmount, s.base, s.quote);

        vm.expectRevert(revertData);
        oracle.getQuote(s.inAmount, s.quote, s.base);

        vm.expectRevert(revertData);
        oracle.getQuotes(s.inAmount, s.base, s.quote);

        vm.expectRevert(revertData);
        oracle.getQuotes(s.inAmount, s.quote, s.base);
    }
}
