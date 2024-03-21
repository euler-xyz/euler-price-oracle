// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {SDaiOracle} from "src/adapter/maker/SDaiOracle.sol";
import {StubMCDPot} from "test/adapter/maker/StubMCDPot.sol";

contract SDaiOracleHelper is Test {
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

    enum Behavior {
        FeedReverts
    }

    SDaiOracle internal oracle;
    mapping(Behavior => bool) private behaviors;

    function _setBehavior(Behavior behavior, bool _status) internal {
        behaviors[behavior] = _status;
    }

    function _deployAndPrepare(FuzzableState memory s) internal {
        s.rate = bound(s.rate, 1e27, 1e36);

        POT = address(new StubMCDPot());
        oracle = new SDaiOracle(DAI, SDAI, POT);

        s.base = SDAI;
        s.quote = DAI;

        s.inAmount = bound(s.inAmount, 1, type(uint128).max);

        if (behaviors[Behavior.FeedReverts]) {
            StubMCDPot(POT).setRevert(true);
        } else {
            StubMCDPot(POT).setRate(s.rate);
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
