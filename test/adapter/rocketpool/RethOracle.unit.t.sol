// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {RethOracleHelper} from "test/adapter/rocketpool/RethOracleHelper.sol";
import {StubReth} from "test/adapter/rocketpool/StubReth.sol";
import {RethOracle} from "src/adapter/rocketpool/RethOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract RethOracleTest is RethOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);
        assertEq(oracle.weth(), WETH);
        assertEq(oracle.reth(), RETH);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        _deployAndPrepare(s);
        vm.assume(otherA != WETH && otherA != RETH);
        vm.assume(otherB != WETH && otherB != RETH);
        assertNotSupported(s.inAmount, WETH, WETH);
        assertNotSupported(s.inAmount, RETH, RETH);
        assertNotSupported(s.inAmount, WETH, otherA);
        assertNotSupported(s.inAmount, otherA, WETH);
        assertNotSupported(s.inAmount, RETH, otherA);
        assertNotSupported(s.inAmount, otherA, RETH);
        assertNotSupported(s.inAmount, otherA, otherA);
        assertNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_RevertsWhen_RethCallReverts(FuzzableState memory s) public {
        _setBehavior(Behavior.FeedReverts, true);
        _deployAndPrepare(s);

        bytes memory err = abi.encodePacked("oops");
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_Weth_Reth_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);

        uint256 expectedOutAmount = s.inAmount * 1e18 / s.rate;

        uint256 outAmount = oracle.getQuote(s.inAmount, WETH, RETH);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, WETH, RETH);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Reth_Weth_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);

        uint256 expectedOutAmount = s.inAmount * s.rate / 1e18;

        uint256 outAmount = oracle.getQuote(s.inAmount, RETH, WETH);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, RETH, WETH);
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
