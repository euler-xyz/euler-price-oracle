// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {IDapiProxy} from "src/adapter/api3/IDapiProxy.sol";
import {API3Oracle} from "src/adapter/api3/API3Oracle.sol";

contract API3OracleHelper is AdapterHelper {
    uint256 internal constant MAX_STALENESS_LOWER_BOUND = 1 minutes;
    uint256 internal constant MAX_STALENESS_UPPER_BOUND = 72 hours;

    struct Bounds {
        uint8 minBaseDecimals;
        uint8 maxBaseDecimals;
        uint8 minQuoteDecimals;
        uint8 maxQuoteDecimals;
        uint256 minInAmount;
        uint256 maxInAmount;
        int224 minAnswer;
        int224 maxAnswer;
    }

    Bounds internal DEFAULT_BOUNDS = Bounds({
        minBaseDecimals: 0,
        maxBaseDecimals: 18,
        minQuoteDecimals: 0,
        maxQuoteDecimals: 18,
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
        // RoundData
        int224 answer;
        uint32 updatedAt;
        // Environment
        uint256 timestamp;
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);
        s.feed = boundAddr(s.feed);
        vm.assume(distinct(s.base, s.quote, s.feed));

        if (behaviors[Behavior.Constructor_MaxStalenessTooLow]) {
            s.maxStaleness = bound(s.maxStaleness, 0, MAX_STALENESS_LOWER_BOUND - 1);
        } else if (behaviors[Behavior.Constructor_MaxStalenessTooHigh]) {
            s.maxStaleness = bound(s.maxStaleness, MAX_STALENESS_UPPER_BOUND + 1, type(uint128).max);
        } else {
            s.maxStaleness = bound(s.maxStaleness, MAX_STALENESS_LOWER_BOUND, MAX_STALENESS_UPPER_BOUND);
        }

        s.baseDecimals = uint8(bound(s.baseDecimals, bounds.minBaseDecimals, bounds.maxBaseDecimals));
        s.quoteDecimals = uint8(bound(s.quoteDecimals, bounds.minQuoteDecimals, bounds.maxQuoteDecimals));

        vm.mockCall(s.base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.baseDecimals));
        vm.mockCall(s.quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.quoteDecimals));

        oracle = address(new API3Oracle(s.base, s.quote, s.feed, s.maxStaleness));

        if (behaviors[Behavior.FeedReturnsZeroPrice]) {
            s.answer = 0;
        } else if (behaviors[Behavior.FeedReturnsNegativePrice]) {
            s.answer = int224(bound(s.answer, type(int224).min, -1));
        } else {
            s.answer = int224(bound(s.answer, bounds.minAnswer, bounds.maxAnswer));
        }

        s.updatedAt = uint32(bound(s.updatedAt, 1, type(uint32).max));

        if (behaviors[Behavior.FeedReturnsStalePrice]) {
            s.timestamp = bound(s.timestamp, s.updatedAt + s.maxStaleness + 1, type(uint256).max);
        } else {
            s.timestamp = bound(s.timestamp, s.updatedAt, s.updatedAt + s.maxStaleness);
        }

        s.inAmount = bound(s.inAmount, bounds.minInAmount, bounds.maxInAmount);

        if (behaviors[Behavior.FeedReverts]) {
            vm.mockCallRevert(s.feed, abi.encodeWithSelector(IDapiProxy.read.selector), "oops");
        } else {
            vm.mockCall(s.feed, abi.encodeWithSelector(IDapiProxy.read.selector), abi.encode(s.answer, s.updatedAt));
        }

        vm.warp(s.timestamp);
    }

    function calcOutAmount(FuzzableState memory s) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDiv(
            s.inAmount, uint256(uint224(s.answer)) * 10 ** s.quoteDecimals, 10 ** (18 + s.baseDecimals)
        );
    }

    function calcOutAmountInverse(FuzzableState memory s) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDiv(
            s.inAmount, 10 ** (18 + s.baseDecimals), uint256(uint224(s.answer)) * 10 ** s.quoteDecimals
        );
    }
}
