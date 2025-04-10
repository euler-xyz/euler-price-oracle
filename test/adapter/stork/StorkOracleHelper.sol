// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {StubStork} from "./StubStork.sol";
import {StorkOracle} from "../../../src/adapter/stork/StorkOracle.sol";
import {StorkStructs} from "../../../src/adapter/stork/IStork.sol";

contract StorkOracleHelper is AdapterHelper {
    uint256 internal constant MAX_STALENESS_UPPER_BOUND = 15 minutes;

    struct Bounds {
        uint8 minBaseDecimals;
        uint8 maxBaseDecimals;
        uint8 minQuoteDecimals;
        uint8 maxQuoteDecimals;
        uint256 minInAmount;
        uint256 maxInAmount;
        int64 minPrice;
        int64 maxPrice;
    }

    Bounds internal DEFAULT_BOUNDS = Bounds({
        minBaseDecimals: 0,
        maxBaseDecimals: 18,
        minQuoteDecimals: 0,
        maxQuoteDecimals: 18,
        minInAmount: 0,
        maxInAmount: type(uint128).max,
        minPrice: 1,
        maxPrice: 1_000_000_000_000
    });

    Bounds internal bounds = DEFAULT_BOUNDS;

    function setBounds(Bounds memory _bounds) internal {
        bounds = _bounds;
    }

    address STORK;

    struct FuzzableState {
        // Config
        address base;
        address quote;
        bytes32 feedId;
        uint256 maxStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        // Answer
        StorkStructs.TemporalNumericValue v;
        // Environment
        uint256 inAmount;
        uint256 timestamp;
    }

    constructor() {
        STORK = address(new StubStork());
    }

    function setUpState(FuzzableState memory s) internal {
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);
        vm.assume(distinct(s.base, s.quote, STORK));
        vm.assume(s.feedId != 0);

        if (behaviors[Behavior.Constructor_MaxStalenessTooHigh]) {
            s.maxStaleness = bound(s.maxStaleness, MAX_STALENESS_UPPER_BOUND + 1, type(uint128).max);
        } else {
            s.maxStaleness = bound(s.maxStaleness, 0, MAX_STALENESS_UPPER_BOUND);
        }

        s.baseDecimals = uint8(bound(s.baseDecimals, bounds.minBaseDecimals, bounds.maxBaseDecimals));
        s.quoteDecimals = uint8(bound(s.quoteDecimals, bounds.minQuoteDecimals, bounds.maxQuoteDecimals));

        vm.mockCall(s.base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.baseDecimals));
        vm.mockCall(s.quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.quoteDecimals));

        if (behaviors[Behavior.FeedReturnsNegativePrice]) {
            s.v.quantizedValue = int192(bound(s.v.quantizedValue, type(int64).min, -1));
        } else if (behaviors[Behavior.FeedReturnsZeroPrice]) {
            s.v.quantizedValue = 0;
        } else {
            s.v.quantizedValue = int192(bound(s.v.quantizedValue, bounds.minPrice, bounds.maxPrice));
        }

        s.v.timestampNs = uint64(bound(uint256(s.v.timestampNs), (1 minutes + 1) * 1e9, type(uint64).max));
        uint256 valueTimestampSeconds = uint256(s.v.timestampNs / 1e9);

        if (behaviors[Behavior.FeedReturnsStalePrice]) {
            s.timestamp = bound(s.timestamp, valueTimestampSeconds + s.maxStaleness + 1, type(uint144).max);
        } else if (behaviors[Behavior.FeedReturnsTooAheadPrice]) {
            s.timestamp = bound(s.timestamp, 0, valueTimestampSeconds - 1 minutes - 1);
        } else {
            s.timestamp = bound(s.timestamp, valueTimestampSeconds - 1 minutes, valueTimestampSeconds + s.maxStaleness);
        }

        if (behaviors[Behavior.FeedReverts]) {
            StubStork(STORK).setRevert(true);
        } else {
            StubStork(STORK).setPrice(s.v);
        }

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);
        vm.warp(s.timestamp);
    }

    function setUpOracle(FuzzableState memory s) internal {
        oracle = address(new StorkOracle(STORK, s.base, s.quote, s.feedId, s.maxStaleness));
    }

    function calcOutAmount(FuzzableState memory s) internal pure returns (uint256) {
        int8 diff = int8(s.baseDecimals) + 18;
        if (diff > 0) {
            return FixedPointMathLib.fullMulDiv(
                s.inAmount, uint256(uint192(s.v.quantizedValue)) * 10 ** s.quoteDecimals, 10 ** (uint8(diff))
            );
        } else {
            return FixedPointMathLib.fullMulDiv(
                s.inAmount, uint256(uint192(s.v.quantizedValue)) * 10 ** (s.quoteDecimals + uint8(-diff)), 1
            );
        }
    }

    function calcOutAmountInverse(FuzzableState memory s) internal pure returns (uint256) {
        int8 diff = int8(s.baseDecimals) + 18;
        if (diff > 0) {
            return FixedPointMathLib.fullMulDiv(
                s.inAmount, 10 ** uint8(diff), uint256(uint192(s.v.quantizedValue)) * 10 ** s.quoteDecimals
            );
        } else {
            return FixedPointMathLib.fullMulDiv(
                s.inAmount, 1, uint256(uint192(s.v.quantizedValue)) * 10 ** (s.quoteDecimals + uint8(-diff))
            );
        }
    }
}
