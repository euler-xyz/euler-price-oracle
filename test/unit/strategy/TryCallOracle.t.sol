// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {TryCallOracleHarness} from "test/utils/TryCallOracleHarness.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";

contract TryCallOracleTest is Test {
    TryCallOracleHarness private immutable harness;

    constructor() {
        harness = new TryCallOracleHarness();
    }

    function test_TryGetQuote_WhenNotIEOracle_ReturnsFalseAndZero(
        address oracle,
        uint256 inAmount,
        address base,
        address quote
    ) public {
        oracle = boundAddr(oracle);
        (bool success, uint256 outAmount) = harness.tryGetQuote(IEOracle(oracle), inAmount, base, quote);

        assertFalse(success);
        assertEq(outAmount, 0);
    }

    function test_TryGetQuote_WhenReturnsInvalidLengthData_ReturnsFalseAndZero(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        bytes memory returnData
    ) public {
        oracle = boundAddr(oracle);
        vm.assume(returnData.length != 32);
        vm.mockCall(oracle, abi.encodeWithSelector(IEOracle.getQuote.selector), returnData);
        (bool success, uint256 outAmount) = harness.tryGetQuote(IEOracle(oracle), inAmount, base, quote);
        assertFalse(success);
        assertEq(outAmount, 0);
    }

    function test_TryGetQuote_WhenReturns32Bytes_ReturnsTrueAndData(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        bytes memory returnData
    ) public {
        oracle = boundAddr(oracle);
        vm.assume(returnData.length == 32);
        vm.mockCall(oracle, abi.encodeWithSelector(IEOracle.getQuote.selector), returnData);
        (bool success, uint256 outAmount) = harness.tryGetQuote(IEOracle(oracle), inAmount, base, quote);
        assertTrue(success);
        assertEq(outAmount, abi.decode(returnData, (uint256)));
    }

    function test_TryGetQuote_WhenReturnsUint256_ReturnsTrueAndData(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        uint256 returnOutAmount
    ) public {
        oracle = boundAddr(oracle);
        vm.mockCall(oracle, abi.encodeWithSelector(IEOracle.getQuote.selector), abi.encode(returnOutAmount));
        (bool success, uint256 outAmount) = harness.tryGetQuote(IEOracle(oracle), inAmount, base, quote);
        assertTrue(success);
        assertEq(outAmount, returnOutAmount);
    }

    function test_TryGetQuotes_WhenNotIEOracle_ReturnsFalseAndZero(
        address oracle,
        uint256 inAmount,
        address base,
        address quote
    ) public {
        oracle = boundAddr(oracle);
        (bool success, uint256 bidOutAmount, uint256 askOutAmount) =
            harness.tryGetQuotes(IEOracle(oracle), inAmount, base, quote);

        assertFalse(success);
        assertEq(bidOutAmount, 0);
        assertEq(askOutAmount, 0);
    }

    function test_TryGetQuotes_WhenReturnsInvalidLengthData_ReturnsFalseAndZero(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        bytes memory returnData
    ) public {
        oracle = boundAddr(oracle);
        vm.assume(returnData.length != 64);
        vm.mockCall(oracle, abi.encodeWithSelector(IEOracle.getQuotes.selector), returnData);
        (bool success, uint256 bidOutAmount, uint256 askOutAmount) =
            harness.tryGetQuotes(IEOracle(oracle), inAmount, base, quote);
        assertFalse(success);
        assertEq(bidOutAmount, 0);
        assertEq(askOutAmount, 0);
    }

    function test_TryGetQuotes_WhenReturns64Bytes_ReturnsTrueAndData(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        uint256 bid,
        uint256 ask
    ) public {
        oracle = boundAddr(oracle);

        bytes memory returnData = abi.encode(bid, ask);
        vm.mockCall(oracle, abi.encodeWithSelector(IEOracle.getQuotes.selector), returnData);
        (bool success, uint256 bidOutAmount, uint256 askOutAmount) =
            harness.tryGetQuotes(IEOracle(oracle), inAmount, base, quote);
        assertTrue(success);
        (uint256 resBidOut, uint256 resAskOut) = abi.decode(returnData, (uint256, uint256));
        assertEq(bidOutAmount, resBidOut);
        assertEq(askOutAmount, resAskOut);
    }

    function test_TryGetQuotes_WhenReturnsTwoUint256s_ReturnsTrueAndData(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        uint256 returnBidOut,
        uint256 returnAskOut
    ) public {
        oracle = boundAddr(oracle);
        vm.mockCall(oracle, abi.encodeWithSelector(IEOracle.getQuotes.selector), abi.encode(returnBidOut, returnAskOut));
        (bool success, uint256 bidOutAmount, uint256 askOutAmount) =
            harness.tryGetQuotes(IEOracle(oracle), inAmount, base, quote);
        assertTrue(success);
        assertEq(bidOutAmount, returnBidOut);
        assertEq(askOutAmount, returnAskOut);
    }
}