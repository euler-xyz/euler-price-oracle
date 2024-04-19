// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SDaiOracle} from "src/adapter/maker/SDaiOracle.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {StubERC4626} from "test/StubERC4626.sol";

contract SDaiOracleHelper is AdapterHelper {
    address internal DAI = makeAddr("DAI");
    address internal SDAI = makeAddr("SDAI");
    uint256 internal RAY = 1e27;

    struct FuzzableState {
        address base;
        address quote;
        // SDai stub (StubERC4626)
        uint256 rate; // exchange rate
        // Environment
        uint256 inAmount;
        uint256 timestamp;
    }

    function setUpState(FuzzableState memory s) internal {
        s.rate = bound(s.rate, 1e18, 1e27);
        SDAI = address(new StubERC4626(DAI, s.rate));
        oracle = address(new SDaiOracle(DAI, SDAI));

        s.base = SDAI;
        s.quote = DAI;

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);
        s.timestamp = bound(s.timestamp, 2 ** 30 + 1, 2 ** 31);
        s.rate = bound(s.rate, 1e18, 1e27);

        if (behaviors[Behavior.FeedReverts]) {
            StubERC4626(SDAI).setRevert(true);
        }

        vm.warp(s.timestamp);
    }
}
