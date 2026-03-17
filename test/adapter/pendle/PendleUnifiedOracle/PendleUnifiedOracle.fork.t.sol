// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {
    PENDLE_ORACLE,
    PENDLE_ETHENA_SUSDE_0925_MARKET,
    PENDLE_ETHENA_SUSDE_0925_PT,
    PENDLE_ETHENA_SUSDE_0925_SY
} from "test/adapter/pendle/PendleAddresses.sol";
import {EETH, EBTC, USDC, USDE, WBTC} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {PendleUnifiedOracle} from "src/adapter/pendle/PendleUnifiedOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract PendleUnifiedOracleForkTest is ForkTest {
    PendleUnifiedOracle oracle;
    /// @dev 1%
    uint256 constant REL_PRECISION = 0.01e18;

    function setUp() public {
        _setUpFork(23238500);
        oracle = new PendleUnifiedOracle(PENDLE_ORACLE);
    }

    /// @dev This market is active. 1 PT-sUSDe0925 = 0.8314 SY-sUSDe. Oracle has no slippage.
    function test_GetQuote_ActiveMarket_sUSDe0925_PT_SY() public {
        oracle.addPair(
            PENDLE_ETHENA_SUSDE_0925_MARKET, PENDLE_ETHENA_SUSDE_0925_PT, PENDLE_ETHENA_SUSDE_0925_SY, 15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_ETHENA_SUSDE_0925_PT, PENDLE_ETHENA_SUSDE_0925_SY);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_ETHENA_SUSDE_0925_PT, PENDLE_ETHENA_SUSDE_0925_SY);
        assertApproxEqRel(outAmount, 0.8314e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_ETHENA_SUSDE_0925_SY, PENDLE_ETHENA_SUSDE_0925_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 =
            oracle.getQuote(outAmount1000, PENDLE_ETHENA_SUSDE_0925_SY, PENDLE_ETHENA_SUSDE_0925_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 PT-sUSDe0925 = 0.9911 USDe.
    function test_GetQuote_ActiveMarket_sUSDe0925_PT_Asset() public {
        oracle.addPair(PENDLE_ETHENA_SUSDE_0925_MARKET, PENDLE_ETHENA_SUSDE_0925_PT, USDE, 15 minutes);

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_ETHENA_SUSDE_0925_PT, USDE);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_ETHENA_SUSDE_0925_PT, USDE);
        assertApproxEqRel(outAmount, 0.9911e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDE, PENDLE_ETHENA_SUSDE_0925_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USDE, PENDLE_ETHENA_SUSDE_0925_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 LP-sUSDe0925 = 2.78426 USDe
    function test_GetQuote_ActiveMarket_sUSDe0925_LP_Asset() public {
        oracle.addPair(PENDLE_ETHENA_SUSDE_0925_MARKET, PENDLE_ETHENA_SUSDE_0925_MARKET, USDE, 15 minutes);

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_ETHENA_SUSDE_0925_MARKET, USDE);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_ETHENA_SUSDE_0925_MARKET, USDE);
        assertApproxEqRel(outAmount, 2.78426e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDE, PENDLE_ETHENA_SUSDE_0925_MARKET);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USDE, PENDLE_ETHENA_SUSDE_0925_MARKET);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 LP-sUSDe0925 = 2.3353 SY-sUSDe. Oracle has no slippage.
    function test_GetQuote_ActiveMarket_sUSDe0925_LP_SY() public {
        oracle.addPair(
            PENDLE_ETHENA_SUSDE_0925_MARKET, PENDLE_ETHENA_SUSDE_0925_MARKET, PENDLE_ETHENA_SUSDE_0925_SY, 15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_ETHENA_SUSDE_0925_MARKET, PENDLE_ETHENA_SUSDE_0925_SY);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_ETHENA_SUSDE_0925_MARKET, PENDLE_ETHENA_SUSDE_0925_SY);
        assertApproxEqRel(outAmount, 2.3353e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_ETHENA_SUSDE_0925_SY, PENDLE_ETHENA_SUSDE_0925_MARKET);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 =
            oracle.getQuote(outAmount1000, PENDLE_ETHENA_SUSDE_0925_SY, PENDLE_ETHENA_SUSDE_0925_MARKET);
        assertEq(outAmountInv1000, 1000e18);
    }
}
