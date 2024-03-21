// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {AggregatorV3Interface} from "src/adapter/chainlink/AggregatorV3Interface.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";

contract ChainlinkOracleHelper is AdapterHelper {
    struct Bounds {
        uint8 minBaseDecimals;
        uint8 maxBaseDecimals;
        uint8 minQuoteDecimals;
        uint8 maxQuoteDecimals;
        uint8 minFeedDecimals;
        uint8 maxFeedDecimals;
        uint256 minInAmount;
        uint256 maxInAmount;
        int256 minAnswer;
        int256 maxAnswer;
    }

    Bounds internal DEFAULT_BOUNDS = Bounds({
        minBaseDecimals: 0,
        maxBaseDecimals: 18,
        minQuoteDecimals: 0,
        maxQuoteDecimals: 18,
        minFeedDecimals: 8,
        maxFeedDecimals: 18,
        minInAmount: 0,
        maxInAmount: type(uint128).max,
        minAnswer: 1,
        maxAnswer: 1e27
    });

    Bounds internal bounds = DEFAULT_BOUNDS;

    function setBounds(Bounds memory _bounds) internal {
        bounds = _bounds;
    }

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

    function setUpState(FuzzableState memory s) internal {
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);
        s.feed = boundAddr(s.feed);
        vm.assume(distinct(s.base, s.quote, s.feed));

        s.maxStaleness = bound(s.maxStaleness, 0, type(uint128).max);

        s.baseDecimals = uint8(bound(s.baseDecimals, bounds.minBaseDecimals, bounds.maxBaseDecimals));
        s.quoteDecimals = uint8(bound(s.quoteDecimals, bounds.minQuoteDecimals, bounds.maxQuoteDecimals));
        s.feedDecimals = uint8(bound(s.feedDecimals, bounds.minFeedDecimals, bounds.maxFeedDecimals));

        vm.mockCall(s.base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.baseDecimals));
        vm.mockCall(s.quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.quoteDecimals));
        vm.mockCall(s.feed, abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(s.feedDecimals));

        oracle = address(new ChainlinkOracle(s.base, s.quote, s.feed, s.maxStaleness));

        if (behaviors[Behavior.FeedReturnsZeroPrice]) {
            s.answer = 0;
        } else if (behaviors[Behavior.FeedReturnsNegativePrice]) {
            s.answer = bound(s.answer, type(int256).min, -1);
        } else {
            s.answer = bound(s.answer, bounds.minAnswer, bounds.maxAnswer);
        }

        s.updatedAt = bound(s.updatedAt, 1, type(uint128).max);

        if (behaviors[Behavior.FeedReturnsStalePrice]) {
            s.timestamp = bound(s.timestamp, s.updatedAt + s.maxStaleness + 1, type(uint256).max);
        } else {
            s.timestamp = bound(s.timestamp, s.updatedAt, s.updatedAt + s.maxStaleness);
        }

        s.inAmount = bound(s.inAmount, bounds.minInAmount, bounds.maxInAmount);

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

    function calcOutAmount(FuzzableState memory s) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDiv(
            s.inAmount, uint256(s.answer) * 10 ** s.quoteDecimals, 10 ** (s.feedDecimals + s.baseDecimals)
        );
    }

    function calcOutAmountInverse(FuzzableState memory s) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDiv(
            s.inAmount, 10 ** (s.feedDecimals + s.baseDecimals), (uint256(s.answer) * 10 ** s.quoteDecimals)
        );
    }
}
