// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPyth} from "@pyth/IPyth.sol";
import {PythStructs} from "@pyth/PythStructs.sol";
import {PythOracleHelper} from "test/adapter/pyth/PythOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";
import {StubPyth} from "test/adapter/pyth/StubPyth.sol";
import {Errors} from "src/lib/Errors.sol";

contract PythOracleTest is PythOracleHelper {
    PythOracle oracle;

    function test_Constructor_Integrity(FuzzableConfig memory c) public {
        oracle = _deploy(c);

        assertEq(address(oracle.pyth()), PYTH);
        assertEq(oracle.base(), c.base);
        assertEq(oracle.quote(), c.quote);
        assertEq(oracle.feedId(), c.feedId);
        assertEq(oracle.maxStaleness(), c.maxStaleness);
    }

    function test_GetQuote_RevertsWhen_InvalidBase(FuzzableConfig memory c, uint256 inAmount, address base) public {
        oracle = _deploy(c);
        vm.assume(base != c.base);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, c.quote));
        oracle.getQuote(inAmount, base, c.quote);
    }

    function test_GetQuote_RevertsWhen_InvalidQuote(FuzzableConfig memory c, uint256 inAmount, address quote) public {
        oracle = _deploy(c);
        vm.assume(quote != c.quote);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, c.base, quote));
        oracle.getQuote(inAmount, c.base, quote);
    }

    function test_GetQuote_RevertsWhen_ZeroPrice(FuzzableConfig memory c, uint256 inAmount, PythStructs.Price memory p)
        public
    {
        oracle = _deploy(c);
        p.price = 0;

        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_NegativePrice(
        FuzzableConfig memory c,
        PythStructs.Price memory p,
        uint256 inAmount
    ) public {
        oracle = _deploy(c);
        _bound(p);
        p.price = int64(bound(p.price, type(int64).min, -1));
        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_ConfidenceIntervalGtMaxPrice(
        FuzzableConfig memory c,
        PythStructs.Price memory p,
        uint256 inAmount
    ) public {
        oracle = _deploy(c);
        _bound(p);
        p.conf = uint64(bound(p.conf, uint64(type(int64).max) + 1, type(uint64).max));
        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_ConfidenceIntervalGtPrice(
        FuzzableConfig memory c,
        PythStructs.Price memory p,
        uint256 inAmount
    ) public {
        oracle = _deploy(c);
        _bound(p);
        p.conf = uint64(bound(p.conf, uint64(p.price) + 1, type(uint64).max));
        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_ExponentTooSmall(
        FuzzableConfig memory c,
        PythStructs.Price memory p,
        uint256 inAmount
    ) public {
        oracle = _deploy(c);
        _bound(p);
        p.expo = int32(bound(p.expo, type(int32).min, -17));
        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuote_RevertsWhen_ExponentTooLarge(
        FuzzableConfig memory c,
        PythStructs.Price memory p,
        uint256 inAmount
    ) public {
        oracle = _deploy(c);
        _bound(p);
        p.expo = int32(bound(p.expo, 17, type(int32).max));
        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuote(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidBase(FuzzableConfig memory c, uint256 inAmount, address base) public {
        oracle = _deploy(c);
        vm.assume(base != c.base);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, base, c.quote));
        oracle.getQuotes(inAmount, base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidQuote(FuzzableConfig memory c, uint256 inAmount, address quote) public {
        oracle = _deploy(c);
        vm.assume(quote != c.quote);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, c.base, quote));
        oracle.getQuotes(inAmount, c.base, quote);
    }

    function test_GetQuotes_RevertsWhen_ZeroPrice(FuzzableConfig memory c, uint256 inAmount, PythStructs.Price memory p)
        public
    {
        oracle = _deploy(c);
        p.price = 0;
        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_NegativePrice(
        FuzzableConfig memory c,
        uint256 inAmount,
        PythStructs.Price memory p
    ) public {
        oracle = _deploy(c);
        _bound(p);
        p.price = int64(bound(p.price, type(int64).min, -1));
        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_ConfidenceIntervalGtMaxPrice(
        FuzzableConfig memory c,
        uint256 inAmount,
        PythStructs.Price memory p
    ) public {
        oracle = _deploy(c);
        _bound(p);
        p.conf = uint64(bound(p.conf, uint64(type(int64).max) + 1, type(uint64).max));
        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_ConfidenceIntervalGtPrice(
        FuzzableConfig memory c,
        uint256 inAmount,
        PythStructs.Price memory p
    ) public {
        oracle = _deploy(c);
        _bound(p);
        p.conf = uint64(bound(p.conf, uint64(p.price) + 1, type(uint64).max));
        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_ExponentTooSmall(
        FuzzableConfig memory c,
        uint256 inAmount,
        PythStructs.Price memory p
    ) public {
        oracle = _deploy(c);
        _bound(p);
        p.expo = int32(bound(p.expo, type(int32).min, -17));
        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_GetQuotes_RevertsWhen_ExponentTooLarge(
        FuzzableConfig memory c,
        uint256 inAmount,
        PythStructs.Price memory p
    ) public {
        oracle = _deploy(c);
        _bound(p);
        p.expo = int32(bound(p.expo, 17, type(int32).max));
        StubPyth(PYTH).setPrice(p);
        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        oracle.getQuotes(inAmount, c.base, c.quote);
    }

    function test_UpdatePrice_Integrity(
        FuzzableConfig memory c,
        address caller,
        bytes[] calldata updateData,
        uint256 value
    ) public {
        oracle = _deploy(c);
        caller = boundAddr(caller);
        vm.deal(caller, value);

        vm.prank(caller);
        oracle.updatePrice{value: value}(updateData);
        assertEq(caller.balance, 0);
    }

    function test_UpdatePrice_RevertsWhen_PythCallReverts(
        FuzzableConfig memory c,
        address caller,
        bytes[] calldata updateData,
        uint256 value
    ) public {
        oracle = _deploy(c);
        caller = boundAddr(caller);
        vm.deal(caller, value);
        StubPyth(PYTH).setRevert(true);

        vm.expectRevert();
        vm.prank(caller);
        oracle.updatePrice{value: value}(updateData);
        assertEq(caller.balance, value);
        assertEq(address(oracle).balance, 0);
    }
}
