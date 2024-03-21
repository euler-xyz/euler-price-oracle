// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {StubStEth} from "test/adapter/lido/StubStEth.sol";
import {LidoOracle} from "src/adapter/lido/LidoOracle.sol";

contract LidoOracleHelper is Test {
    address internal STETH;
    address internal WSTETH = makeAddr("WSTETH");

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

    LidoOracle internal oracle;
    mapping(Behavior => bool) private behaviors;

    function _setBehavior(Behavior behavior, bool _status) internal {
        behaviors[behavior] = _status;
    }

    function _deployAndPrepare(FuzzableState memory s) internal {
        s.rate = bound(s.rate, 1e18, 1e27);

        STETH = address(new StubStEth());
        oracle = new LidoOracle(STETH, WSTETH);

        s.base = WSTETH;
        s.quote = STETH;

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);

        if (behaviors[Behavior.FeedReverts]) {
            StubStEth(STETH).setRevert(true);
        } else {
            StubStEth(STETH).setRate(s.rate);
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
