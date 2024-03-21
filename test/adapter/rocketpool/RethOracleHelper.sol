// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {StubReth} from "test/adapter/rocketpool/StubReth.sol";
import {RethOracle} from "src/adapter/rocketpool/RethOracle.sol";

contract RethOracleHelper is Test {
    address internal RETH;
    address internal WETH = makeAddr("WETH");

    struct FuzzableState {
        address base;
        address quote;
        // Answer
        uint256 rate;
        uint256 inAmount;
    }

    enum Behavior {
        FeedReverts
    }

    RethOracle internal oracle;
    mapping(Behavior => bool) private behaviors;

    function _setBehavior(Behavior behavior, bool _status) internal {
        behaviors[behavior] = _status;
    }

    function _deploy() internal returns (RethOracle) {
        RETH = address(new StubReth());
        return new RethOracle(WETH, RETH);
    }

    function _deployAndPrepare(FuzzableState memory s) internal {
        s.rate = bound(s.rate, 1e18, 1e27);

        RETH = address(new StubReth());
        oracle = new RethOracle(WETH, RETH);

        s.base = RETH;
        s.quote = WETH;

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);

        if (behaviors[Behavior.FeedReverts]) {
            StubReth(RETH).setRevert(true);
        } else {
            StubReth(RETH).setRate(s.rate);
        }
    }

    function expectRevertForAllQuotePermutations(FuzzableState memory s, bytes memory revertData) internal {
        vm.expectRevert(revertData);
        oracle.getQuote(s.inAmount, s.base, s.quote);

        vm.expectRevert(revertData);
        oracle.getQuote(s.inAmount, s.quote, s.base);

        vm.expectRevert(revertData);
        oracle.getQuotes(s.inAmount, s.base, s.quote);

        vm.expectRevert(revertData);
        oracle.getQuotes(s.inAmount, s.quote, s.base);
    }
}
