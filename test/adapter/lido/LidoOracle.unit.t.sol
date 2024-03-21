// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {LidoOracleHelper} from "test/adapter/lido/LidoOracleHelper.sol";
import {IStEth} from "src/adapter/lido/IStEth.sol";
import {LidoOracle} from "src/adapter/lido/LidoOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract LidoOracleTest is LidoOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);
        assertEq(oracle.stEth(), STETH);
        assertEq(oracle.wstEth(), WSTETH);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        _deployAndPrepare(s);
        vm.assume(otherA != WSTETH && otherA != STETH);
        vm.assume(otherB != WSTETH && otherB != STETH);
        assertNotSupported(s.inAmount, WSTETH, WSTETH);
        assertNotSupported(s.inAmount, STETH, STETH);
        assertNotSupported(s.inAmount, WSTETH, otherA);
        assertNotSupported(s.inAmount, otherA, WSTETH);
        assertNotSupported(s.inAmount, STETH, otherA);
        assertNotSupported(s.inAmount, otherA, STETH);
        assertNotSupported(s.inAmount, otherA, otherA);
        assertNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_RevertsWhen_StEthCallReverts(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReverts, true);
        _deployAndPrepare(s);

        bytes memory err = abi.encodePacked("oops");
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_StEth_WstEth_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);

        uint256 expectedOutAmount = s.inAmount * 1e18 / s.rate;

        uint256 outAmount = oracle.getQuote(s.inAmount, STETH, WSTETH);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, STETH, WSTETH);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_WstEth_StEth_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);

        uint256 expectedOutAmount = s.inAmount * s.rate / 1e18;

        uint256 outAmount = oracle.getQuote(s.inAmount, WSTETH, STETH);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, WSTETH, STETH);
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
