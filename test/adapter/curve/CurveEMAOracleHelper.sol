// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {CurveEMAOracle} from "src/adapter/curve/CurveEMAOracle.sol";
import {ICurvePool} from "src/adapter/curve/ICurvePool.sol";

contract CurveEMAOracleHelper is AdapterHelper {
    struct FuzzableState {
        // Config
        address coins_0;
        address pool;
        address base;
        uint256 priceOracleIndex;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        // Pool Oracle
        uint256 price;
        // Environment
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.coins_0 = boundAddr(s.coins_0);
        s.pool = boundAddr(s.pool);
        s.base = boundAddr(s.base);

        vm.assume(distinct(s.base, s.coins_0, s.pool));

        if (behaviors[Behavior.Constructor_LpMode]) {
            s.priceOracleIndex = type(uint256).max;
        } else {
            vm.assume(s.priceOracleIndex != type(uint256).max);
        }

        vm.mockCall(s.pool, abi.encodeWithSelector(ICurvePool.coins.selector, 0), abi.encode(s.coins_0));

        s.baseDecimals = uint8(bound(s.baseDecimals, 6, 18));
        s.quoteDecimals = uint8(bound(s.quoteDecimals, 6, 18));

        vm.mockCall(s.base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.baseDecimals));
        vm.mockCall(s.coins_0, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.quoteDecimals));

        oracle = address(new CurveEMAOracle(s.pool, s.base, s.priceOracleIndex));

        s.price = bound(s.price, 1, 1e27);
        s.inAmount = bound(s.inAmount, 0, type(uint128).max);

        if (s.priceOracleIndex == type(uint256).max) {
            vm.mockCall(s.pool, abi.encodeWithSelector(bytes4(keccak256("price_oracle()"))), abi.encode(s.price));
        } else {
            vm.mockCall(
                s.pool,
                abi.encodeWithSelector(bytes4(keccak256("price_oracle(uint256)")), s.priceOracleIndex),
                abi.encode(s.price)
            );
        }
    }

    function calcOutAmount(FuzzableState memory s) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDiv(
            s.inAmount, uint256(s.price) * 10 ** s.quoteDecimals, 10 ** (18 + s.baseDecimals)
        );
    }

    function calcOutAmountInverse(FuzzableState memory s) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDiv(
            s.inAmount, 10 ** (18 + s.baseDecimals), (uint256(s.price) * 10 ** s.quoteDecimals)
        );
    }
}
