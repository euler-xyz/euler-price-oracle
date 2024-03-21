// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {AggregatorV3Interface} from "src/adapter/chainlink/AggregatorV3Interface.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";

contract ChainlinkOracleHelper is Test {
    struct FuzzableState {
        // Config
        address base;
        address quote;
        address feed;
        uint256 maxStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        uint8 feedDecimals;
        // RoundData
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
        // Environment
        uint256 timestamp;
        uint256 inAmount;
    }

    enum Behavior {
        FeedReverts,
        FeedReturnsZero,
        FeedReturnsNegative,
        FeedReturnsStalePrice
    }

    ChainlinkOracle internal oracle;
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
        vm.mockCall(s.feed, abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(s.feedDecimals));

        oracle = new ChainlinkOracle(s.base, s.quote, s.feed, s.maxStaleness);

        if (behaviors[Behavior.FeedReturnsZero]) {
            s.answer = 0;
        } else if (behaviors[Behavior.FeedReturnsNegative]) {
            s.answer = bound(s.answer, type(int256).min, -1);
        } else {
            s.answer = bound(s.answer, 1, type(int80).max);
        }

        s.updatedAt = bound(s.updatedAt, 1, type(uint128).max);

        if (behaviors[Behavior.FeedReturnsStalePrice]) {
            s.timestamp = bound(s.timestamp, s.updatedAt + s.maxStaleness + 1, type(uint256).max);
        } else {
            s.timestamp = bound(s.timestamp, s.updatedAt, s.updatedAt + s.maxStaleness);
        }

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);

        if (behaviors[Behavior.FeedReverts]) {
            vm.mockCallRevert(s.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), "oops");
        } else {
            vm.mockCall(
                s.feed,
                abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
                abi.encode(s.roundId, s.answer, s.startedAt, s.updatedAt, s.answeredInRound)
            );
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
