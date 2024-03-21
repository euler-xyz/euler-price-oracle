// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";

contract AdapterPropTest is Test {
    address adapter;
    address base;
    address quote;

    struct PropArgs_Bidirectional {
        uint256 _dummy;
    }

    function checkProp(PropArgs_Bidirectional memory p) internal view {
        (bool successBQ,) = _tryGetQuote(1, base, quote);
        (bool successQB,) = _tryGetQuote(1, quote, base);
        assertTrue(successBQ);
        assertTrue(successQB);
        p._dummy;
    }

    struct PropArgs_NoOtherPaths {
        uint256 inAmount;
        address tokenA;
        address tokenB;
    }

    function checkProp(PropArgs_NoOtherPaths memory p) internal view {
        vm.assume(!((p.tokenA == base && p.tokenB == quote) || (p.tokenA == quote && p.tokenB == base)));
        (bool success,) = _tryGetQuote(1, p.tokenA, p.tokenB);
        assertFalse(success);
    }

    struct PropArgs_ContinuousDomain {
        uint256 in0;
        uint256 in1;
        uint256 in2;
    }

    function checkProp(PropArgs_ContinuousDomain memory p) internal view {
        // in0 < in1 < in2
        p.in0 = bound(p.in0, 0, type(uint256).max - 2);
        p.in1 = bound(p.in1, p.in0 + 1, type(uint256).max - 1);
        p.in2 = bound(p.in2, p.in1 + 1, type(uint256).max);

        (bool success0,) = _tryGetQuote(p.in0, base, quote);
        (bool success1,) = _tryGetQuote(p.in1, base, quote);
        (bool success2,) = _tryGetQuote(p.in2, base, quote);

        if (success0 == success2) assertEq(success1, success2);
    }

    struct PropArgs_OutAmountIncreasing {
        uint256 in0;
        uint256 in1;
    }

    function checkProp(PropArgs_OutAmountIncreasing memory p) internal view {
        // in0 < in1
        p.in0 = bound(p.in0, 0, type(uint256).max - 2);
        p.in1 = bound(p.in1, p.in0, type(uint256).max - 1);

        (bool success0, uint256 outAmount0) = _tryGetQuote(p.in0, base, quote);
        (bool success1, uint256 outAmount1) = _tryGetQuote(p.in1, base, quote);
        if (success0 && success1) assertLe(outAmount0, outAmount1);

        (success0, outAmount0) = _tryGetQuote(p.in0, quote, base);
        (success1, outAmount1) = _tryGetQuote(p.in1, quote, base);
        if (success0 && success1) assertLe(outAmount0, outAmount1);
    }

    function _tryGetQuote(uint256 inAmount, address _base, address _quote) internal view returns (bool, uint256) {
        bytes memory data = abi.encodeCall(IPriceOracle.getQuote, (inAmount, _base, _quote));
        (bool success, bytes memory returnData) = adapter.staticcall(data);
        uint256 outAmount = success ? abi.decode(returnData, (uint256)) : 0;
        return (success, outAmount);
    }
}
