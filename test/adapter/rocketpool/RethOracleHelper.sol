// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {StubReth} from "test/adapter/rocketpool/StubReth.sol";
import {RethOracle} from "src/adapter/rocketpool/RethOracle.sol";

contract RethOracleHelper is Test {
    address internal WETH = makeAddr("DAI");
    address internal RETH;

    struct FuzzableAnswer {
        uint256 rate;
    }

    function _deploy() internal returns (RethOracle) {
        RETH = address(new StubReth());
        return new RethOracle(WETH, RETH);
    }

    function _prepareAnswer(FuzzableAnswer memory c) internal {
        c.rate = bound(c.rate, 1e18, 1e27);
        StubReth(RETH).setRate(c.rate);
    }
}
