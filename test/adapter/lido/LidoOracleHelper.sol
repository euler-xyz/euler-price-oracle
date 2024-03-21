// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {StubStEth} from "test/adapter/lido/StubStEth.sol";
import {LidoOracle} from "src/adapter/lido/LidoOracle.sol";

contract LidoOracleHelper is AdapterHelper {
    address internal STETH;
    address internal WSTETH = makeAddr("WSTETH");

    struct FuzzableState {
        address base;
        address quote;
        // Answer
        uint256 rate;
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.rate = bound(s.rate, 1e18, 1e27);

        STETH = address(new StubStEth());
        oracle = address(new LidoOracle(STETH, WSTETH));

        s.base = WSTETH;
        s.quote = STETH;

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);

        if (behaviors[Behavior.FeedReverts]) {
            StubStEth(STETH).setRevert(true);
        } else {
            StubStEth(STETH).setRate(s.rate);
        }
    }
}
