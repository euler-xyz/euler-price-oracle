// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {SDaiOracle} from "src/adapter/maker/SDaiOracle.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {StubMCDPot} from "test/adapter/maker/StubMCDPot.sol";

contract SDaiOracleHelper is AdapterHelper {
    address internal DAI = makeAddr("DAI");
    address internal SDAI = makeAddr("SDAI");
    address internal POT;
    uint256 internal RAY = 1e27;

    struct FuzzableState {
        address base;
        address quote;
        // DSR Pot
        uint256 rho; // last update
        uint256 chi; // exchange rate at last update
        uint256 dsr; // accumulation rate per second
        // Environment
        uint256 inAmount;
        uint256 timestamp;
    }

    function setUpState(FuzzableState memory s) internal {
        POT = address(new StubMCDPot());
        oracle = address(new SDaiOracle(DAI, SDAI, POT));

        s.base = SDAI;
        s.quote = DAI;

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);
        s.timestamp = bound(s.timestamp, 2 ** 30 + 1, 2 ** 31);
        if (behaviors[Behavior.FeedReturnsStaleRate]) {
            s.rho = bound(s.rho, s.timestamp - 31_536_000, s.timestamp - 1);
        } else {
            s.rho = s.timestamp;
        }
        s.chi = bound(s.chi, 1e27, 1e28);
        s.dsr = bound(s.dsr, 1e27 + 1, 1e27 + 1e20);

        StubMCDPot(POT).setParams(s.chi, s.rho, s.dsr);
        if (behaviors[Behavior.FeedReverts]) {
            StubMCDPot(POT).setRevert(true);
        }

        vm.warp(s.timestamp);
    }

    function getUpdatedRate(FuzzableState memory s) internal view returns (uint256) {
        return FixedPointMathLib.rpow(s.dsr, block.timestamp - s.rho, RAY) * s.dsr / RAY;
    }
}
