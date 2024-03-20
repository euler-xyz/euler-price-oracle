// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {LidoOracleHelper} from "test/adapter/lido/LidoOracleHelper.sol";
import {IStEth} from "src/adapter/lido/IStEth.sol";
import {LidoOracle} from "src/adapter/lido/LidoOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract LidoOracleTest is LidoOracleHelper {
    LidoOracle oracle;

    function setUp() public {
        oracle = _deploy();
    }

    function test_Constructor_Integrity() public view {
        assertEq(oracle.stEth(), STETH);
        assertEq(oracle.wstEth(), WSTETH);
    }

    function test_GetQuote_RevertsWhen_InvalidBase_A(uint256 inAmount, address base) public {
        vm.assume(base != WSTETH);
        address quote = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_InvalidBase_B(uint256 inAmount, address base) public {
        vm.assume(base != STETH);
        address quote = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_InvalidQuote_A(uint256 inAmount, address quote) public {
        vm.assume(quote != WSTETH);
        address base = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_InvalidQuote_B(uint256 inAmount, address quote) public {
        vm.assume(quote != STETH);
        address base = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_SameTokens_StEth(uint256 inAmount) public {
        address base = STETH;
        address quote = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_SameTokens_WstEth(uint256 inAmount) public {
        address base = WSTETH;
        address quote = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_StEth_WstEth_StEthCallReverts(FuzzableAnswer memory c, uint256 inAmount)
        public
    {
        _prepareAnswer(c);
        vm.mockCallRevert(STETH, abi.encodeWithSelector(IStEth.getSharesByPooledEth.selector), "oops");

        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuote(inAmount, STETH, WSTETH);
    }

    function test_GetQuote_RevertsWhen_WstEth_StEth_StEthCallReverts(FuzzableAnswer memory c, uint256 inAmount)
        public
    {
        _prepareAnswer(c);
        vm.mockCallRevert(STETH, abi.encodeWithSelector(IStEth.getPooledEthByShares.selector), "oops");

        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuote(inAmount, WSTETH, STETH);
    }

    function test_GetQuote_StEth_WstEth_Integrity(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 1, type(uint128).max);

        uint256 outAmount = oracle.getQuote(inAmount, STETH, WSTETH);
        assertEq(outAmount, inAmount * 1e18 / c.rate);
    }

    function test_GetQuote_WstEth_StEth_Integrity(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 1, type(uint128).max);

        uint256 outAmount = oracle.getQuote(inAmount, WSTETH, STETH);
        assertEq(outAmount, inAmount * c.rate / 1e18);
    }

    function test_GetQuotes_RevertsWhen_InvalidBase_A(uint256 inAmount, address base) public {
        vm.assume(base != WSTETH);
        address quote = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidBase_B(uint256 inAmount, address base) public {
        vm.assume(base != STETH);
        address quote = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidQuote_A(uint256 inAmount, address quote) public {
        vm.assume(quote != WSTETH);
        address base = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidQuote_B(uint256 inAmount, address quote) public {
        vm.assume(quote != STETH);
        address base = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_SameTokens_StEth(uint256 inAmount) public {
        address base = STETH;
        address quote = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_SameTokens_WstEth(uint256 inAmount) public {
        address base = WSTETH;
        address quote = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_StEth_WstEth_StEthCallReverts(FuzzableAnswer memory c, uint256 inAmount)
        public
    {
        _prepareAnswer(c);
        vm.mockCallRevert(STETH, abi.encodeWithSelector(IStEth.getSharesByPooledEth.selector), "oops");

        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuote(inAmount, STETH, WSTETH);
    }

    function test_GetQuotes_RevertsWhen_WstEth_StEth_StEthCallReverts(FuzzableAnswer memory c, uint256 inAmount)
        public
    {
        _prepareAnswer(c);
        vm.mockCallRevert(STETH, abi.encodeWithSelector(IStEth.getPooledEthByShares.selector), "oops");

        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuotes(inAmount, WSTETH, STETH);
    }

    function test_GetQuotes_StEth_WstEth_Integrity(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 1, type(uint128).max);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, STETH, WSTETH);
        assertEq(bidOutAmount, inAmount * 1e18 / c.rate);
        assertEq(askOutAmount, inAmount * 1e18 / c.rate);
    }

    function test_GetQuotes_WstEth_StEth_Integrity(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 1, type(uint128).max);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, WSTETH, STETH);
        assertEq(bidOutAmount, inAmount * c.rate / 1e18);
        assertEq(askOutAmount, inAmount * c.rate / 1e18);
    }
}
