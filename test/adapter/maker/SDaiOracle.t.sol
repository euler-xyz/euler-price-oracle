// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {SDaiOracleHelper} from "test/adapter/maker/SDaiOracleHelper.sol";
import {IPot} from "src/adapter/maker/IPot.sol";
import {SDaiOracle} from "src/adapter/maker/SDaiOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract SDaiOracleTest is SDaiOracleHelper {
    SDaiOracle oracle;

    function setUp() public {
        oracle = _deploy();
    }

    function test_Constructor_Integrity() public view {
        assertEq(oracle.dai(), DAI);
        assertEq(oracle.sDai(), SDAI);
        assertEq(oracle.dsrPot(), POT);
    }

    function test_GetQuote_RevertsWhen_InvalidBase_A(uint256 inAmount, address base) public {
        vm.assume(base != SDAI);
        address quote = DAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_InvalidBase_B(uint256 inAmount, address base) public {
        vm.assume(base != DAI);
        address quote = SDAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_InvalidQuote_A(uint256 inAmount, address quote) public {
        vm.assume(quote != SDAI);
        address base = DAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_InvalidQuote_B(uint256 inAmount, address quote) public {
        vm.assume(quote != DAI);
        address base = SDAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_SameTokens_Dai(uint256 inAmount) public {
        address base = DAI;
        address quote = DAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_SameTokens_SDai(uint256 inAmount) public {
        address base = SDAI;
        address quote = SDAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_SDai_Dai_DsrPotCallReverts(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        vm.mockCallRevert(POT, abi.encodeWithSelector(IPot.chi.selector), "oops");

        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuote(inAmount, SDAI, DAI);
    }

    function test_GetQuote_RevertsWhen_Dai_SDai_DsrPotCallReverts(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        vm.mockCallRevert(POT, abi.encodeWithSelector(IPot.chi.selector), "oops");

        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuote(inAmount, DAI, SDAI);
    }

    function test_GetQuote_SDai_Dai_Integrity(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 1, type(uint128).max);

        uint256 outAmount = oracle.getQuote(inAmount, SDAI, DAI);
        assertEq(outAmount, inAmount * c.rate / 1e27);
    }

    function test_GetQuote_Dai_SDai_Integrity(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 1, type(uint128).max);

        uint256 outAmount = oracle.getQuote(inAmount, DAI, SDAI);
        assertEq(outAmount, inAmount * 1e27 / c.rate);
    }

    function test_GetQuotes_RevertsWhen_InvalidBase_A(uint256 inAmount, address base) public {
        vm.assume(base != SDAI);
        address quote = DAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidBase_B(uint256 inAmount, address base) public {
        vm.assume(base != DAI);
        address quote = SDAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidQuote_A(uint256 inAmount, address quote) public {
        vm.assume(quote != SDAI);
        address base = DAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidQuote_B(uint256 inAmount, address quote) public {
        vm.assume(quote != DAI);
        address base = SDAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_SameTokens_Dai(uint256 inAmount) public {
        address base = DAI;
        address quote = DAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_SameTokens_SDai(uint256 inAmount) public {
        address base = SDAI;
        address quote = SDAI;

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_SDai_Dai_DsrPotCallReverts(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        vm.mockCallRevert(POT, abi.encodeWithSelector(IPot.chi.selector), "oops");

        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuotes(inAmount, SDAI, DAI);
    }

    function test_GetQuotes_RevertsWhen_Dai_SDai_DsrPotCallReverts(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        vm.mockCallRevert(POT, abi.encodeWithSelector(IPot.chi.selector), "oops");

        vm.expectRevert(abi.encodePacked("oops"));
        oracle.getQuotes(inAmount, DAI, SDAI);
    }

    function test_GetQuotes_SDai_Dai_Integrity(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 1, type(uint128).max);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, SDAI, DAI);
        uint256 expectedOutAmount = inAmount * c.rate / 1e27;
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_GetQuotes_Dai_SDai_Integrity(FuzzableAnswer memory c, uint256 inAmount) public {
        _prepareAnswer(c);
        inAmount = bound(inAmount, 1, type(uint128).max);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, DAI, SDAI);
        uint256 expectedOutAmount = inAmount * 1e27 / c.rate;
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }
}
