// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {SDaiOracleHelper} from "test/adapter/maker/SDaiOracleHelper.sol";
import {SDaiOracle} from "src/adapter/maker/SDaiOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract SDaiOracleTest is SDaiOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);
        assertEq(oracle.dai(), DAI);
        assertEq(oracle.sDai(), SDAI);
        assertEq(oracle.dsrPot(), POT);
    }

    function test_GetQuote_GetQuotes_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB)
        public
    {
        _deployAndPrepare(s);
        vm.assume(otherA != SDAI && otherA != DAI);
        vm.assume(otherB != SDAI && otherB != DAI);
        assertNotSupported(s.inAmount, SDAI, SDAI);
        assertNotSupported(s.inAmount, DAI, DAI);
        assertNotSupported(s.inAmount, SDAI, otherA);
        assertNotSupported(s.inAmount, otherA, SDAI);
        assertNotSupported(s.inAmount, DAI, otherA);
        assertNotSupported(s.inAmount, otherA, DAI);
        assertNotSupported(s.inAmount, otherA, otherA);
        assertNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_RevertsWhen_DsrPotCallReverts(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReverts, true);
        _deployAndPrepare(s);

        bytes memory err = abi.encodePacked("oops");
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_SDai_Dai_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);

        uint256 expectedOutAmount = s.inAmount * s.rate / 1e27;

        uint256 outAmount = oracle.getQuote(s.inAmount, SDAI, DAI);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, SDAI, DAI);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Dai_SDai_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);

        uint256 expectedOutAmount = s.inAmount * 1e27 / s.rate;

        uint256 outAmount = oracle.getQuote(s.inAmount, DAI, SDAI);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, DAI, SDAI);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function assertNotSupported(uint256 inAmount, address tokenA, address tokenB) internal {
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, tokenA, tokenB));
        oracle.getQuote(inAmount, tokenA, tokenB);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, tokenA, tokenB));
        oracle.getQuotes(inAmount, tokenA, tokenB);
    }
}
