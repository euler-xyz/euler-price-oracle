// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPyth} from "@pyth/IPyth.sol";
import {PythStructs} from "@pyth/PythStructs.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {StubPyth} from "test/adapter/pyth/StubPyth.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";

contract PythOracleHelper is AdapterHelper {
    address PYTH;

    struct FuzzableState {
        // Config
        address base;
        address quote;
        bytes32 feedId;
        uint256 maxStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        // Answer
        PythStructs.Price p;
        // Environment
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        PYTH = address(new StubPyth());
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);
        vm.assume(distinct(s.base, s.quote, PYTH));

        s.maxStaleness = bound(s.maxStaleness, 0, type(uint32).max);

        s.baseDecimals = uint8(bound(s.baseDecimals, 2, 18));
        s.quoteDecimals = uint8(bound(s.quoteDecimals, 2, 18));

        vm.mockCall(s.base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.baseDecimals));
        vm.mockCall(s.quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.quoteDecimals));

        if (behaviors[Behavior.FeedReturnsZeroPrice]) {
            s.p.price = 0;
        } else if (behaviors[Behavior.FeedReturnsNegativePrice]) {
            s.p.price = int64(bound(s.p.price, type(int64).min, -1));
        } else {
            s.p.price = int64(bound(s.p.price, 1, type(int32).max));
        }

        if (behaviors[Behavior.FeedReturnsConfTooWide]) {
            s.p.conf = uint64(bound(s.p.conf, uint64(s.p.price) / 20 + 1, type(uint64).max));
        } else {
            s.p.conf = uint64(bound(s.p.conf, 0, uint64(s.p.price) / 20));
        }

        if (behaviors[Behavior.FeedReturnsExpoTooLow]) {
            s.p.expo = int32(bound(s.p.expo, type(int32).min, -17));
        } else if (behaviors[Behavior.FeedReturnsExpoTooHigh]) {
            s.p.expo = int32(bound(s.p.expo, 17, type(int32).max));
        } else {
            s.p.expo = int32(bound(s.p.expo, -16, 16));
        }

        if (behaviors[Behavior.FeedReverts]) {
            StubPyth(PYTH).setRevert(true);
        } else {
            StubPyth(PYTH).setPrice(s.p);
        }

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);

        oracle = address(new PythOracle(PYTH, s.base, s.quote, s.feedId, s.maxStaleness));
    }
}
