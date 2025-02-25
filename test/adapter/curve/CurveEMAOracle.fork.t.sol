// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ForkTest} from "test/utils/ForkTest.sol";
import {
    CURVE_PT_WSTUSR_WSTUSR_POOL,
    SPECTRA_PT_WSTUSR,
    WSTUSR,
    CURVE_TRICRYPTOV2_POOL,
    CURVE_CRVUSD_USDC_POOL,
    CURVE_STABLENG_USD0_POOL
} from "test/adapter/curve/CurveAddresses.sol";
import {WETH, WBTC, USDT, CRVUSD, USDC, USD0, USD0PP} from "test/utils/EthereumAddresses.sol";
import {CurveEMAOracle} from "src/adapter/curve/CurveEMAOracle.sol";

contract CurveEMAOracleForkTest is ForkTest {
    /// @dev 1%
    uint256 constant REL_PRECISION = 0.01e18;

    CurveEMAOracle oracle;

    function setUp() public {
        _setUpFork(21708630);
    }

    function test_TriCryptoV2_3Coins_WBTC_USDT() public {
        oracle = new CurveEMAOracle(CURVE_TRICRYPTOV2_POOL, WBTC, 0);
        assertEq(oracle.pool(), CURVE_TRICRYPTOV2_POOL);
        assertEq(oracle.base(), WBTC);
        assertEq(oracle.quote(), USDT);
        assertEq(oracle.priceOracleIndex(), 0);

        uint256 outAmount = oracle.getQuote(1e8, WBTC, USDT);
        assertApproxEqRel(outAmount, 104574e6, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDT, WBTC);
        assertApproxEqRel(outAmountInv, 1e8, REL_PRECISION);
    }

    function test_TriCryptoV2_3Coins_WETH_USDT() public {
        oracle = new CurveEMAOracle(CURVE_TRICRYPTOV2_POOL, WETH, 1);
        assertEq(oracle.pool(), CURVE_TRICRYPTOV2_POOL);
        assertEq(oracle.base(), WETH);
        assertEq(oracle.quote(), USDT);
        assertEq(oracle.priceOracleIndex(), 1);

        uint256 outAmount = oracle.getQuote(1e18, WETH, USDT);
        assertApproxEqRel(outAmount, 3300e6, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDT, WETH);
        assertApproxEqRel(outAmountInv, 1e18, REL_PRECISION);
    }

    function test_CRVUSD_CRVUSD_USDC() public {
        oracle = new CurveEMAOracle(CURVE_CRVUSD_USDC_POOL, CRVUSD, type(uint256).max);
        assertEq(oracle.pool(), CURVE_CRVUSD_USDC_POOL);
        assertEq(oracle.base(), CRVUSD);
        assertEq(oracle.quote(), USDC);
        assertEq(oracle.priceOracleIndex(), type(uint256).max);

        uint256 outAmount = oracle.getQuote(1e18, CRVUSD, USDC);
        assertApproxEqRel(outAmount, 1e6, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDC, CRVUSD);
        assertApproxEqRel(outAmountInv, 1e18, REL_PRECISION);
    }

    function test_Special_SpectraPool_WSTUSR() public {
        oracle = new CurveEMAOracle(CURVE_PT_WSTUSR_WSTUSR_POOL, SPECTRA_PT_WSTUSR, type(uint256).max);
        assertEq(oracle.pool(), CURVE_PT_WSTUSR_WSTUSR_POOL);
        assertEq(oracle.base(), SPECTRA_PT_WSTUSR);
        assertEq(oracle.quote(), WSTUSR);
        assertEq(oracle.priceOracleIndex(), type(uint256).max);

        uint256 outAmount = oracle.getQuote(1e18, SPECTRA_PT_WSTUSR, WSTUSR);
        assertApproxEqRel(outAmount, 0.92201e18, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, WSTUSR, SPECTRA_PT_WSTUSR);
        assertApproxEqRel(outAmountInv, 1e18, REL_PRECISION);
    }

    function test_StableNG_USD0() public {
        oracle = new CurveEMAOracle(CURVE_STABLENG_USD0_POOL, USD0PP, 0);
        assertEq(oracle.pool(), CURVE_STABLENG_USD0_POOL);
        assertEq(oracle.base(), USD0PP);
        assertEq(oracle.quote(), USD0);
        assertEq(oracle.priceOracleIndex(), 0);

        uint256 outAmount = oracle.getQuote(1e18, USD0PP, USD0);
        assertApproxEqRel(outAmount, 0.9237e18, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, USD0, USD0PP);
        assertApproxEqRel(outAmountInv, 1e18, REL_PRECISION);
    }
}
