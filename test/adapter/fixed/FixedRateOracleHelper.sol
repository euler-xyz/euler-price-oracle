// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {FixedRateOracle} from "src/adapter/fixed/FixedRateOracle.sol";

contract FixedRateOracleHelper is AdapterHelper {
    struct FuzzableState {
        // Config
        address base;
        address quote;
        uint256 rate;
        // Environment
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);
        s.rate = bound(s.rate, 1, type(uint128).max);

        vm.assume(s.base != s.quote);

        oracle = address(new FixedRateOracle(s.base, s.quote, s.rate));
        s.inAmount = bound(s.inAmount, 0, type(uint128).max);
    }
}
