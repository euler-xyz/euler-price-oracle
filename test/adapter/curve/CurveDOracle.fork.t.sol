// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ForkTest} from "test/utils/ForkTest.sol";
import {
    CURVE_STABLENG_USD0_POOL
} from "test/adapter/curve/CurveAddresses.sol";
import {USD0, USD0PP} from "test/utils/EthereumAddresses.sol";
import {CurveDOracle} from "src/adapter/curve/CurveDOracle.sol";

contract CurveDOracleForkTest is ForkTest {
    /// @dev 1%
    uint256 constant REL_PRECISION = 0.01e18;

    CurveDOracle oracle;

    function setUp() public {
        _setUpFork(23276200);
    }

    function test_StableNG_USD0() public {
        oracle = new CurveDOracle(CURVE_STABLENG_USD0_POOL, 0);
        assertEq(oracle.pool(), CURVE_STABLENG_USD0_POOL);
        assertEq(oracle.quote(), USD0);

        uint256 outAmount = oracle.getQuote(1_000e18, CURVE_STABLENG_USD0_POOL, USD0);
        assertApproxEqRel(outAmount, 1_011e18, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, USD0, CURVE_STABLENG_USD0_POOL);
        assertApproxEqRel(outAmountInv, 1_000e18, REL_PRECISION);
    }
}
