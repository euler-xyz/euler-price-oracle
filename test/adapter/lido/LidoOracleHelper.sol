// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {StubStEth} from "test/adapter/lido/StubStEth.sol";
import {LidoOracle} from "src/adapter/lido/LidoOracle.sol";

contract LidoOracleHelper is Test {
    address internal STETH;
    address internal WSTETH = makeAddr("WSTETH");

    struct FuzzableAnswer {
        uint256 rate;
    }

    function _deploy() internal returns (LidoOracle) {
        STETH = address(new StubStEth());
        return new LidoOracle(STETH, WSTETH);
    }

    function _prepareAnswer(FuzzableAnswer memory c) internal {
        c.rate = bound(c.rate, 1e18, 1e27);
        StubStEth(STETH).setRate(c.rate);
    }
}
