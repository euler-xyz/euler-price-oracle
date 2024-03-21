// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {SDaiOracle} from "src/adapter/maker/SDaiOracle.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {StubMCDPot} from "test/adapter/maker/StubMCDPot.sol";

contract SDaiOracleHelper is AdapterHelper {
    address internal DAI = makeAddr("DAI");
    address internal SDAI = makeAddr("SDAI");
    address internal POT;

    struct FuzzableState {
        address base;
        address quote;
        // Answer
        uint256 rate;
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.rate = bound(s.rate, 1e27, 1e36);

        POT = address(new StubMCDPot());
        oracle = address(new SDaiOracle(DAI, SDAI, POT));

        s.base = SDAI;
        s.quote = DAI;

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);

        if (behaviors[Behavior.FeedReverts]) {
            StubMCDPot(POT).setRevert(true);
        } else {
            StubMCDPot(POT).setRate(s.rate);
        }
    }
}
