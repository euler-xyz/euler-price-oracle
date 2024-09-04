// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {LidoFundamentalOracleHelper} from "test/adapter/lido/LidoFundamentalOracleHelper.sol";
import {STETH, WSTETH, WETH} from "test/utils/EthereumAddresses.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {LidoFundamentalOracle} from "src/adapter/lido/LidoFundamentalOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract LidoFundamentalOracleTest is LidoFundamentalOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        setUpState(s);
        assertEq(LidoFundamentalOracle(oracle).STETH(), STETH);
        assertEq(LidoFundamentalOracle(oracle).WSTETH(), WSTETH);
        assertEq(LidoFundamentalOracle(oracle).WETH(), WETH);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        setUpState(s);
        otherA = boundAddr(otherA);
        otherB = boundAddr(otherB);
        vm.assume(otherA != WSTETH && otherA != WETH);
        vm.assume(otherB != WSTETH && otherB != WETH);
        expectNotSupported(s.inAmount, WSTETH, WSTETH);
        expectNotSupported(s.inAmount, WETH, WETH);
        expectNotSupported(s.inAmount, WSTETH, otherA);
        expectNotSupported(s.inAmount, otherA, WSTETH);
        expectNotSupported(s.inAmount, WETH, otherA);
        expectNotSupported(s.inAmount, otherA, WETH);
        expectNotSupported(s.inAmount, otherA, otherA);
        expectNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_RevertsWhen_WethCallReverts(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReverts, true);
        setUpState(s);
        expectRevertForAllQuotePermutations(s.inAmount, WETH, WSTETH, "");
    }

    function test_Quote_Weth_WstEth_Integrity(FuzzableState memory s) public {
        setUpState(s);

        uint256 expectedOutAmount = s.inAmount * 1e18 / s.rate;

        uint256 outAmount = LidoFundamentalOracle(oracle).getQuote(s.inAmount, WETH, WSTETH);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = LidoFundamentalOracle(oracle).getQuotes(s.inAmount, WETH, WSTETH);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_WstEth_Weth_Integrity(FuzzableState memory s) public {
        setUpState(s);

        uint256 expectedOutAmount = s.inAmount * s.rate / 1e18;

        uint256 outAmount = LidoFundamentalOracle(oracle).getQuote(s.inAmount, WSTETH, WETH);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = LidoFundamentalOracle(oracle).getQuotes(s.inAmount, WSTETH, WETH);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }
}
