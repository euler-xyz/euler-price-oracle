// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {RethOracleHelper} from "test/adapter/rocketpool/RethOracleHelper.sol";
import {StubReth} from "test/adapter/rocketpool/StubReth.sol";
import {RethOracle} from "src/adapter/rocketpool/RethOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract RethOracleTest is RethOracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        setUpState(s);
        assertEq(RethOracle(oracle).weth(), WETH);
        assertEq(RethOracle(oracle).reth(), RETH);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        setUpState(s);
        vm.assume(otherA != WETH && otherA != RETH);
        vm.assume(otherB != WETH && otherB != RETH);
        expectNotSupported(s.inAmount, WETH, WETH);
        expectNotSupported(s.inAmount, RETH, RETH);
        expectNotSupported(s.inAmount, WETH, otherA);
        expectNotSupported(s.inAmount, otherA, WETH);
        expectNotSupported(s.inAmount, RETH, otherA);
        expectNotSupported(s.inAmount, otherA, RETH);
        expectNotSupported(s.inAmount, otherA, otherA);
        expectNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_RevertsWhen_RethCallReverts(FuzzableState memory s) public {
        setBehavior(Behavior.FeedReverts, true);
        setUpState(s);

        bytes memory err = abi.encodePacked("oops");
        expectRevertForAllQuotePermutations(s.inAmount, s.base, s.quote, err);
    }

    function test_Quote_Weth_Reth_Integrity(FuzzableState memory s) public {
        setUpState(s);

        uint256 expectedOutAmount = s.inAmount * 1e18 / s.rate;

        uint256 outAmount = RethOracle(oracle).getQuote(s.inAmount, WETH, RETH);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = RethOracle(oracle).getQuotes(s.inAmount, WETH, RETH);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Reth_Weth_Integrity(FuzzableState memory s) public {
        setUpState(s);

        uint256 expectedOutAmount = s.inAmount * s.rate / 1e18;

        uint256 outAmount = RethOracle(oracle).getQuote(s.inAmount, RETH, WETH);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = RethOracle(oracle).getQuotes(s.inAmount, RETH, WETH);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }
}
