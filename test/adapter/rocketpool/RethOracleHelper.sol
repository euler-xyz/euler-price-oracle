// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {StubReth} from "test/adapter/rocketpool/StubReth.sol";
import {RethOracle} from "src/adapter/rocketpool/RethOracle.sol";

contract RethOracleHelper is AdapterHelper {
    address internal RETH;
    address internal WETH = makeAddr("WETH");

    struct FuzzableState {
        address base;
        address quote;
        // Answer
        uint256 rate;
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.rate = bound(s.rate, 1e18, 1e27);

        RETH = address(new StubReth());
        oracle = address(new RethOracle(WETH, RETH));

        s.base = RETH;
        s.quote = WETH;

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);

        if (behaviors[Behavior.FeedReverts]) {
            StubReth(RETH).setRevert(true);
        } else {
            StubReth(RETH).setRate(s.rate);
        }
    }
}
