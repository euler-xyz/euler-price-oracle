// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IPMarket} from "@pendle/core-v2/interfaces/IPMarket.sol";
import {IPPYLpOracle} from "@pendle/core-v2/interfaces/IPPYLpOracle.sol";
import {IStandardizedYield} from "@pendle/core-v2/interfaces/IStandardizedYield.sol";
import {IPYieldToken} from "@pendle/core-v2/interfaces/IPYieldToken.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {PendleOracle} from "src/adapter/pendle/PendleOracle.sol";

contract PendleOracleHelper is AdapterHelper {
    struct FuzzableState {
        // Config
        address pendleOracle;
        address pendleMarket;
        uint32 twapWindow;
        address base;
        address quote;
        // Oracle State
        bool increaseCardinalityRequired;
        bool oldestObservationSatisfied;
        // Market Assets
        address sy;
        address pt;
        address yt;
        address asset;
        // Market State
        uint256 expiry;
        uint256 syExchangeRate;
        uint256 pyIndexStored;
        bool doCacheIndexSameBlock;
        uint256 pyIndexLastUpdatedBlock;
        uint216 lnImpliedRateCumulative0;
        uint216 lnImpliedRateCumulative1;
        // Environment
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.pendleOracle = boundAddr(s.pendleOracle);
        s.pendleMarket = boundAddr(s.pendleMarket);
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);
        s.sy = boundAddr(s.sy);
        s.pt = boundAddr(s.pt);
        s.yt = boundAddr(s.yt);
        s.asset = boundAddr(s.asset);

        vm.assume(distinct(s.pendleMarket, s.pendleOracle, s.sy, s.pt, s.yt, s.asset));

        if (behaviors[Behavior.Constructor_BaseNotPt]) {
            vm.assume(s.base != s.pt);
        } else {
            s.base = s.pt;
        }

        if (behaviors[Behavior.Constructor_QuoteNotSyOrAsset]) {
            vm.assume(s.quote != s.sy && s.quote != s.asset);
        } else {
            s.quote = uint160(s.quote) % 2 == 0 ? s.sy : s.asset;
        }

        if (behaviors[Behavior.Constructor_TwapWindowTooShort]) {
            s.twapWindow = uint32(bound(s.twapWindow, 1, 5 minutes - 1));
        } else if (behaviors[Behavior.Constructor_TwapWindowTooLong]) {
            s.twapWindow = uint32(bound(s.twapWindow, 60 minutes + 1, type(uint32).max));
        } else {
            s.twapWindow = uint32(bound(s.twapWindow, 5 minutes + 1, 60 minutes));
        }

        if (behaviors[Behavior.Constructor_CardinalityTooSmall]) {
            s.increaseCardinalityRequired = true;
        } else {
            s.increaseCardinalityRequired = false;
        }

        if (behaviors[Behavior.Constructor_TooFewObservations]) {
            s.oldestObservationSatisfied = false;
        } else {
            s.oldestObservationSatisfied = true;
        }

        s.syExchangeRate = bound(s.syExchangeRate, 1e9, 1e27);
        s.pyIndexStored = bound(s.pyIndexStored, 1e9, 1e27);
        s.pyIndexLastUpdatedBlock = bound(s.pyIndexStored, 0, block.number);
        s.lnImpliedRateCumulative0 = uint216(bound(s.lnImpliedRateCumulative0, 1e9, 1e27));
        s.lnImpliedRateCumulative1 = uint216(bound(s.lnImpliedRateCumulative1, s.lnImpliedRateCumulative0, 1e27));
        s.expiry = bound(s.expiry, 0, block.timestamp);

        vm.mockCall(
            s.pendleOracle,
            abi.encodeWithSelector(IPPYLpOracle.getOracleState.selector, s.pendleMarket, s.twapWindow),
            abi.encode(s.increaseCardinalityRequired, uint16(0), s.oldestObservationSatisfied)
        );

        vm.mockCall(s.pendleMarket, abi.encodeWithSelector(IPMarket.readTokens.selector), abi.encode(s.sy, s.pt, s.yt));

        vm.mockCall(
            s.sy, abi.encodeWithSelector(IStandardizedYield.assetInfo.selector), abi.encode(uint8(0), s.asset, uint8(0))
        );

        vm.mockCall(
            s.sy, abi.encodeWithSelector(IStandardizedYield.exchangeRate.selector), abi.encode(s.syExchangeRate)
        );

        vm.mockCall(s.yt, abi.encodeWithSelector(IPYieldToken.pyIndexStored.selector), abi.encode(s.pyIndexStored));

        vm.mockCall(
            s.yt,
            abi.encodeWithSelector(IPYieldToken.doCacheIndexSameBlock.selector),
            abi.encode(s.doCacheIndexSameBlock)
        );

        vm.mockCall(
            s.yt,
            abi.encodeWithSelector(IPYieldToken.pyIndexLastUpdatedBlock.selector),
            abi.encode(s.pyIndexLastUpdatedBlock)
        );

        vm.mockCall(s.pendleMarket, abi.encodeWithSelector(IPMarket.expiry.selector), abi.encode(s.expiry));

        oracle = address(new PendleOracle(s.pendleOracle, s.pendleMarket, s.base, s.quote, s.twapWindow));

        s.inAmount = bound(s.inAmount, 0, type(uint128).max);
    }
}
