// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {RethOracleHelper} from "test/adapter/rocketpool/RethOracleHelper.sol";
import {StubReth} from "test/adapter/rocketpool/StubReth.sol";
import {RethOracle} from "src/adapter/rocketpool/RethOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract RethOracleTest is RethOracleHelper {
    RethOracle oracle;

    function setUp() public {
        oracle = _deploy();
    }

    function test_Constructor_Integrity() public view {
        assertEq(oracle.weth(), WETH);
        assertEq(oracle.reth(), RETH);
    }

    function test_GetQuote_GetQuotes_RevertsWhen_InvalidTokens(uint256 inAmount, address otherA, address otherB)
        public
    {
        vm.assume(otherA != WETH && otherA != RETH);
        vm.assume(otherB != WETH && otherB != RETH);
        assertNotSupported(inAmount, WETH, WETH);
        assertNotSupported(inAmount, RETH, RETH);
        assertNotSupported(inAmount, WETH, otherA);
        assertNotSupported(inAmount, otherA, WETH);
        assertNotSupported(inAmount, RETH, otherA);
        assertNotSupported(inAmount, otherA, RETH);
        assertNotSupported(inAmount, otherA, otherA);
        assertNotSupported(inAmount, otherA, otherB);
    }

    function test_GetQuotes_Weth_Reth_RevertsWhen_CallReverts(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 0, type(uint128).max);
        StubReth(RETH).setRevert(true);
        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuotes(inAmount, WETH, RETH);
    }

    function test_GetQuotes_Reth_Weth_RevertsWhen_CallReverts(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 0, type(uint128).max);
        StubReth(RETH).setRevert(true);

        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuotes(inAmount, RETH, WETH);
    }

    function test_GetQuotes_Weth_Reth_Integrity(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 0, type(uint128).max);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, WETH, RETH);
        assertEq(bidOutAmount, inAmount * 1e18 / c.rate);
        assertEq(askOutAmount, inAmount * 1e18 / c.rate);
    }

    function test_GetQuotes_Reth_Weth_Integrity(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 0, type(uint128).max);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, RETH, WETH);
        assertEq(bidOutAmount, inAmount * c.rate / 1e18);
        assertEq(askOutAmount, inAmount * c.rate / 1e18);
    }

    function assertNotSupported(uint256 inAmount, address tokenA, address tokenB) internal {
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, tokenA, tokenB));
        oracle.getQuote(inAmount, tokenA, tokenB);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, tokenA, tokenB));
        oracle.getQuotes(inAmount, tokenA, tokenB);
    }
}
