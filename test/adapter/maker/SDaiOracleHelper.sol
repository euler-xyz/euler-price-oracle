// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {SDaiOracle} from "src/adapter/maker/SDaiOracle.sol";
import {StubMCDPot} from "test/adapter/maker/StubMCDPot.sol";

contract SDaiOracleHelper is Test {
    address internal DAI = makeAddr("DAI");
    address internal SDAI = makeAddr("SDAI");
    address internal POT;

    struct FuzzableAnswer {
        uint256 rate;
    }

    function _deploy() internal returns (SDaiOracle) {
        POT = address(new StubMCDPot());
        return new SDaiOracle(DAI, SDAI, POT);
    }

    function _prepareAnswer(FuzzableAnswer memory c) internal {
        c.rate = bound(c.rate, 1e27, 1e36);
        StubMCDPot(POT).setRate(c.rate);
    }
}
