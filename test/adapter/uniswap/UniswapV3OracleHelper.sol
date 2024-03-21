// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IUniswapV3PoolDerivedState} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolDerivedState.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {UniswapV3Oracle} from "src/adapter/uniswap/UniswapV3Oracle.sol";

contract UniswapV3OracleHelper is Test {
    struct FuzzableState {
        // Config
        address tokenA;
        address tokenB;
        uint24 fee;
        uint32 twapWindow;
        address uniswapV3Factory;
        address pool;
        // Pool Oracle
        int56 tickCumulative0; // larger value
        int56 tickCumulative1;
        // Environment
        uint256 inAmount;
    }

    enum Behavior {
        TwapWindowTooShort,
        NoPool,
        InAmountTooLarge,
        ObserveReverts
    }

    UniswapV3Oracle internal oracle;
    mapping(Behavior => bool) private behaviors;

    function _setBehavior(Behavior behavior, bool _status) internal {
        behaviors[behavior] = _status;
    }

    function _deployAndPrepare(FuzzableState memory s) internal {
        s.tokenA = boundAddr(s.tokenA);
        s.tokenB = boundAddr(s.tokenB);
        s.uniswapV3Factory = boundAddr(s.uniswapV3Factory);

        if (behaviors[Behavior.NoPool]) {
            s.pool = address(0);
        } else {
            s.pool = boundAddr(s.pool);
        }
        vm.assume(distinct(s.tokenA, s.tokenB, s.uniswapV3Factory, s.pool));

        vm.mockCall(
            s.uniswapV3Factory,
            abi.encodeWithSelector(IUniswapV3Factory.getPool.selector, s.tokenA, s.tokenB, s.fee),
            abi.encode(s.pool)
        );

        if (behaviors[Behavior.TwapWindowTooShort]) {
            s.twapWindow = uint32(bound(s.twapWindow, 1, 59));
        } else {
            s.twapWindow = uint32(bound(s.twapWindow, 60, 9 days));
        }

        oracle = new UniswapV3Oracle(s.tokenA, s.tokenB, s.fee, s.twapWindow, s.uniswapV3Factory);

        s.tickCumulative0 = int56(bound(s.tickCumulative0, type(int56).min, type(int56).max));
        s.tickCumulative1 = int56(bound(s.tickCumulative1, s.tickCumulative0, type(int56).max));
        unchecked {
            int256 diff = int256(s.tickCumulative1) - int256(s.tickCumulative0);
            vm.assume(diff >= type(int56).min && diff <= type(int56).max);
        }
        int24 tick = int24((s.tickCumulative1 - s.tickCumulative0) / int32(s.twapWindow));
        vm.assume(tick > -887272 && tick < 887272);

        if (behaviors[Behavior.ObserveReverts]) {
            vm.mockCallRevert(s.pool, abi.encodeWithSelector(IUniswapV3PoolDerivedState.observe.selector), "oops");
        } else {
            int56[] memory tickCumulatives = new int56[](2);
            tickCumulatives[0] = s.tickCumulative0;
            tickCumulatives[1] = s.tickCumulative1;
            uint160[] memory secondsPerLiquidityCumulativeX128s = new uint160[](2);
            vm.mockCall(
                s.pool,
                abi.encodeWithSelector(IUniswapV3PoolDerivedState.observe.selector),
                abi.encode(tickCumulatives, secondsPerLiquidityCumulativeX128s)
            );
        }

        if (behaviors[Behavior.InAmountTooLarge]) {
            s.inAmount = bound(s.inAmount, uint256(type(uint128).max) + 1, type(uint256).max);
        } else {
            s.inAmount = bound(s.inAmount, 0, type(uint128).max);
        }
    }

    function expectRevertForAllQuotePermutations(FuzzableState memory s, bytes memory revertData) internal {
        vm.expectRevert(revertData);
        oracle.getQuote(s.inAmount, s.tokenA, s.tokenB);

        vm.expectRevert(revertData);
        oracle.getQuote(s.inAmount, s.tokenB, s.tokenA);

        vm.expectRevert(revertData);
        oracle.getQuotes(s.inAmount, s.tokenA, s.tokenB);

        vm.expectRevert(revertData);
        oracle.getQuotes(s.inAmount, s.tokenB, s.tokenA);
    }
}
