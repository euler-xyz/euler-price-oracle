// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {IRateProvider} from "src/adapter/rate/IRateProvider.sol";
import {RateProviderOracle} from "src/adapter/rate/RateProviderOracle.sol";

contract RateProviderOracleHelper is AdapterHelper {
    struct FuzzableState {
        // Config
        address rateProvider;
        address base;
        address quote;
        // Oracle State
        uint256 rate;
        // Environment
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.rateProvider = boundAddr(s.rateProvider);
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);

        vm.assume(distinct(s.rateProvider, s.base, s.quote));

        if (behaviors[Behavior.FeedReturnsZeroPrice]) {
            s.rate = 0;
        } else {
            s.rate = bound(s.rate, 1, type(uint128).max);
        }

        if (behaviors[Behavior.FeedReverts]) {
            vm.mockCallRevert(s.rateProvider, abi.encodeWithSelector(IRateProvider.getRate.selector), "");
        } else {
            vm.mockCall(s.rateProvider, abi.encodeWithSelector(IRateProvider.getRate.selector), abi.encode(s.rate));
        }

        oracle = address(new RateProviderOracle(s.base, s.quote, s.rateProvider));
        s.inAmount = bound(s.inAmount, 0, type(uint128).max);
    }
}
