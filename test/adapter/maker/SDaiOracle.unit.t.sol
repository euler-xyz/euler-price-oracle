// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {SDaiOracleHelper} from "test/adapter/maker/SDaiOracleHelper.sol";
import {DAI, SDAI} from "test/utils/EthereumAddresses.sol";
import {SDaiOracle} from "src/adapter/maker/SDaiOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract SDaiOracleTest is SDaiOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        setUpState(s);
        assertEq(SDaiOracle(oracle).DAI(), DAI);
        assertEq(SDaiOracle(oracle).SDAI(), SDAI);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        setUpState(s);
        vm.assume(otherA != SDAI && otherA != DAI);
        vm.assume(otherB != SDAI && otherB != DAI);
        expectNotSupported(s.inAmount, SDAI, SDAI);
        expectNotSupported(s.inAmount, DAI, DAI);
        expectNotSupported(s.inAmount, SDAI, otherA);
        expectNotSupported(s.inAmount, otherA, SDAI);
        expectNotSupported(s.inAmount, DAI, otherA);
        expectNotSupported(s.inAmount, otherA, DAI);
        expectNotSupported(s.inAmount, otherA, otherA);
        expectNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_RevertsWhen_SDaiCallReverts(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReverts, true);
        setUpState(s);
        expectRevertForAllQuotePermutations(s.inAmount, DAI, SDAI, "");
    }

    function test_Quote_SDai_Dai_Integrity(FuzzableState memory s) public {
        setUpState(s);

        uint256 expectedOutAmount = s.inAmount * s.rate / 1e18;

        uint256 outAmount = SDaiOracle(oracle).getQuote(s.inAmount, SDAI, DAI);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = SDaiOracle(oracle).getQuotes(s.inAmount, SDAI, DAI);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Dai_SDai_Integrity(FuzzableState memory s) public {
        setUpState(s);

        uint256 expectedOutAmount = s.inAmount * 1e18 / s.rate;

        uint256 outAmount = SDaiOracle(oracle).getQuote(s.inAmount, DAI, SDAI);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = SDaiOracle(oracle).getQuotes(s.inAmount, DAI, SDAI);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }
}
