// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {IChronicle} from "src/adapter/chronicle/IChronicle.sol";
import {ChronicleOracle} from "src/adapter/chronicle/ChronicleOracle.sol";

contract ChronicleOracleHelper is Test {
    struct FuzzableState {
        // Config
        address base;
        address quote;
        address feed;
        uint256 maxStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        uint8 feedDecimals;
        // Answer
        uint256 value;
        uint256 age;
        // Environment
        uint256 timestamp;
        uint256 inAmount;
    }

    enum Behavior {
        FeedReverts,
        FeedReturnsZero,
        FeedReturnsStalePrice
    }

    ChronicleOracle internal oracle;
    mapping(Behavior => bool) private behaviors;

    function _setBehavior(Behavior behavior, bool _status) internal {
        behaviors[behavior] = _status;
    }

    function _deployAndPrepare(FuzzableState memory s) internal {
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);
        s.feed = boundAddr(s.feed);
        vm.assume(distinct(s.base, s.quote, s.feed));

        s.maxStaleness = bound(s.maxStaleness, 0, type(uint128).max);

        s.baseDecimals = uint8(bound(s.baseDecimals, 2, 18));
        s.quoteDecimals = uint8(bound(s.quoteDecimals, 2, 18));
        s.feedDecimals = uint8(bound(s.feedDecimals, 2, 18));

        vm.mockCall(s.base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.baseDecimals));
        vm.mockCall(s.quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.quoteDecimals));
        vm.mockCall(s.feed, abi.encodeWithSelector(IChronicle.decimals.selector), abi.encode(s.feedDecimals));

        oracle = new ChronicleOracle(s.base, s.quote, s.feed, s.maxStaleness);

        if (behaviors[Behavior.FeedReturnsZero]) {
            s.value = 0;
        } else {
            s.value = bound(s.value, 1, type(uint80).max);
        }

        s.age = bound(s.age, 0, type(uint128).max);
        if (behaviors[Behavior.FeedReturnsStalePrice]) {
            s.timestamp = bound(s.timestamp, s.age + s.maxStaleness + 1, type(uint256).max);
        } else {
            s.timestamp = bound(s.timestamp, s.age, s.age + s.maxStaleness);
        }

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);

        if (behaviors[Behavior.FeedReverts]) {
            vm.mockCallRevert(s.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), "oops");
        } else {
            vm.mockCall(s.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(s.value, s.age));
        }

        vm.warp(s.timestamp);
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
