// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IUniswapV3PoolActions} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolActions.sol";
import {IUniswapV3PoolState} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolState.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {UniswapV3OracleHelper} from "test/adapter/uniswap/UniswapV3OracleHelper.sol";
import {UniswapV3Oracle} from "src/adapter/uniswap/UniswapV3Oracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract UniswapV3OracleTest is UniswapV3OracleHelper {
    function test_Constructor_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);
        assertEq(oracle.tokenA(), s.tokenA);
        assertEq(oracle.tokenB(), s.tokenB);
        assertEq(oracle.fee(), s.fee);
        assertEq(oracle.twapWindow(), s.twapWindow);
    }

    function test_Constructor_RevertsWhen_TwapWindowTooShort(FuzzableState memory s) public {
        _setBehavior(Behavior.TwapWindowTooShort, true);
        vm.expectRevert();
        _deployAndPrepare(s);
    }

    function test_Constructor_RevertsWhen_PoolAddressZero(FuzzableState memory s) public {
        _setBehavior(Behavior.NoPool, true);
        vm.expectRevert();
        _deployAndPrepare(s);
    }

    function test_Quote_RevertsWhen_InvalidTokens(FuzzableState memory s, address otherA, address otherB) public {
        _deployAndPrepare(s);
        vm.assume(otherA != s.tokenA && otherA != s.tokenB);
        vm.assume(otherB != s.tokenA && otherB != s.tokenB);
        assertNotSupported(s.inAmount, s.tokenA, s.tokenA);
        assertNotSupported(s.inAmount, s.tokenB, s.tokenB);
        assertNotSupported(s.inAmount, s.tokenA, otherA);
        assertNotSupported(s.inAmount, otherA, s.tokenA);
        assertNotSupported(s.inAmount, s.tokenB, otherA);
        assertNotSupported(s.inAmount, otherA, s.tokenB);
        assertNotSupported(s.inAmount, otherA, otherA);
        assertNotSupported(s.inAmount, otherA, otherB);
    }

    function test_Quote_RevertsWhen_InAmountGtUint128(FuzzableState memory s) public {
        _setBehavior(Behavior.InAmountTooLarge, true);
        _deployAndPrepare(s);
        bytes memory err = abi.encodeWithSelector(Errors.PriceOracle_Overflow.selector);
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_RevertsWhen_ObserveReverts(FuzzableState memory s) public {
        _setBehavior(Behavior.ObserveReverts, true);
        _deployAndPrepare(s);
        bytes memory err = abi.encodePacked("oops");
        expectRevertForAllQuotePermutations(s, err);
    }

    function test_Quote_Integrity(FuzzableState memory s) public {
        _deployAndPrepare(s);

        int24 tick = int24((s.tickCumulative1 - s.tickCumulative0) / int32(s.twapWindow));
        uint256 expectedOutAmount = OracleLibrary.getQuoteAtTick(tick, uint128(s.inAmount), s.tokenA, s.tokenB);

        uint256 outAmount = oracle.getQuote(s.inAmount, s.tokenA, s.tokenB);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, s.tokenA, s.tokenB);
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }

    function test_Quote_Integrity_Inverse(FuzzableState memory s) public {
        _deployAndPrepare(s);

        int24 tick = int24((s.tickCumulative1 - s.tickCumulative0) / int32(s.twapWindow));
        uint256 expectedOutAmount = OracleLibrary.getQuoteAtTick(tick, uint128(s.inAmount), s.tokenB, s.tokenA);

        uint256 outAmount = oracle.getQuote(s.inAmount, s.tokenB, s.tokenA);
        assertEq(outAmount, expectedOutAmount);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(s.inAmount, s.tokenB, s.tokenA);
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
