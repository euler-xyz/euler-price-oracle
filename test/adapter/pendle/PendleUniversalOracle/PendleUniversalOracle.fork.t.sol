// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {
    PENDLE_ORACLE,
    PENDLE_EETH_0624_MARKET,
    PENDLE_EETH_0624_PT,
    PENDLE_EETH_0624_SY,
    PENDLE_STETH_0323_MARKET,
    PENDLE_STETH_0323_PT,
    PENDLE_STETH_0323_SY,
    PENDLE_SUSDE_0924_MARKET,
    PENDLE_SUSDE_0924_PT,
    PENDLE_SUSDE_0924_SY,
    PENDLE_EBTC_1224_MARKET,
    PENDLE_EBTC_1224_PT,
    PENDLE_EBTC_1224_SY,
    PENDLE_CORN_LBTC_1224_MARKET,
    PENDLE_CORN_LBTC_1224_PT,
    PENDLE_CORN_LBTC_1224_SY,
    PENDLE_CORN_UNIBTC_1224_MARKET,
    PENDLE_CORN_UNIBTC_1224_PT,
    PENDLE_CORN_UNIBTC_1224_SY,
    PENDLE_CORN_SOLVBTCBBN_1224_MARKET,
    PENDLE_CORN_SOLVBTCBBN_1224_PT,
    PENDLE_CORN_SOLVBTCBBN_1224_SY
} from "test/adapter/pendle/PendleAddresses.sol";
import {EETH, EBTC, USDC, USDE, WBTC} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {PendleUniversalOracle} from "src/adapter/pendle/PendleUniversalOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract PendleUniversalOracleForkTest is ForkTest {
    /// @dev 1%
    uint256 constant REL_PRECISION = 0.01e18;

    function setUp() public {
        _setUpFork(20803385);
    }

    function test_Constructor_Integrity() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, PENDLE_EETH_0624_PT, PENDLE_EETH_0624_SY, 15 minutes
        );
        assertEq(oracle.pendleMarket(), PENDLE_EETH_0624_MARKET);
        assertEq(oracle.twapWindow(), 15 minutes);
        assertEq(oracle.base(), PENDLE_EETH_0624_PT);
        assertEq(oracle.quote(), PENDLE_EETH_0624_SY);
    }

    /// @dev This market is active. 1 PT-sUSDe0924 = 0.9064 SY-sUSDe. Oracle has no slippage.
    function test_GetQuote_ActiveMarket_sUSDe0924_PT_SY() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_SUSDE_0924_MARKET, PENDLE_SUSDE_0924_PT, PENDLE_SUSDE_0924_SY, 15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_SUSDE_0924_PT, PENDLE_SUSDE_0924_SY);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_SUSDE_0924_PT, PENDLE_SUSDE_0924_SY);
        assertApproxEqRel(outAmount, 0.9064e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_SUSDE_0924_SY, PENDLE_SUSDE_0924_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, PENDLE_SUSDE_0924_SY, PENDLE_SUSDE_0924_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 PT-sUSDe0924 = 0.9956 USDe. Oracle has no slippage.
    function test_GetQuote_ActiveMarket_sUSDe0924_PT_Asset() public {
        PendleUniversalOracle oracle =
            new PendleUniversalOracle(PENDLE_ORACLE, PENDLE_SUSDE_0924_MARKET, PENDLE_SUSDE_0924_PT, USDE, 15 minutes);

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_SUSDE_0924_PT, USDE);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_SUSDE_0924_PT, USDE);
        assertApproxEqRel(outAmount, 0.9956e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDE, PENDLE_SUSDE_0924_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USDE, PENDLE_SUSDE_0924_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 LP-sUSDe0924 = 1.8960 SY-sUSDe.
    function test_GetQuote_ActiveMarket_sUSDe0924_LP_SY() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_SUSDE_0924_MARKET, PENDLE_SUSDE_0924_MARKET, PENDLE_SUSDE_0924_SY, 15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_SUSDE_0924_MARKET, PENDLE_SUSDE_0924_SY);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_SUSDE_0924_MARKET, PENDLE_SUSDE_0924_SY);
        assertApproxEqRel(outAmount, 1.896e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_SUSDE_0924_SY, PENDLE_SUSDE_0924_MARKET);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, PENDLE_SUSDE_0924_SY, PENDLE_SUSDE_0924_MARKET);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 LP-sUSDe0924 = 2.0890 USDe.
    function test_GetQuote_ActiveMarket_sUSDe0924_LP_Asset() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_SUSDE_0924_MARKET, PENDLE_SUSDE_0924_MARKET, USDE, 15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_SUSDE_0924_MARKET, USDE);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_SUSDE_0924_MARKET, USDE);
        assertApproxEqRel(outAmount, 2.089e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDE, PENDLE_SUSDE_0924_MARKET);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USDE, PENDLE_SUSDE_0924_MARKET);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 PT-eBTC1224 = 0.9849 SY-eBTC. Oracle has no slippage.
    function test_GetQuote_ActiveMarket_eBTC1224_PT_SY() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_EBTC_1224_MARKET, PENDLE_EBTC_1224_PT, PENDLE_EBTC_1224_SY, 15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EBTC_1224_PT, PENDLE_EBTC_1224_SY);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_EBTC_1224_PT, PENDLE_EBTC_1224_SY);
        assertApproxEqRel(outAmount, 0.9849e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_EBTC_1224_SY, PENDLE_EBTC_1224_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, PENDLE_EBTC_1224_SY, PENDLE_EBTC_1224_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 PT-eBTC1224 = 0.9849 eBTC. Oracle has no slippage.
    function test_GetQuote_ActiveMarket_eBTC1224_PT_Asset() public {
        PendleUniversalOracle oracle =
            new PendleUniversalOracle(PENDLE_ORACLE, PENDLE_EBTC_1224_MARKET, PENDLE_EBTC_1224_PT, EBTC, 15 minutes);

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EBTC_1224_PT, EBTC);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_EBTC_1224_PT, EBTC);
        assertApproxEqRel(outAmount, 0.9849e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, EBTC, PENDLE_EBTC_1224_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, EBTC, PENDLE_EBTC_1224_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 LP-eBTC1224 = 1.9698 SY-eBTC.
    function test_GetQuote_ActiveMarket_eBTC1224_LP_SY() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_EBTC_1224_MARKET, PENDLE_EBTC_1224_MARKET, PENDLE_EBTC_1224_SY, 15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EBTC_1224_MARKET, PENDLE_EBTC_1224_SY);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_EBTC_1224_MARKET, PENDLE_EBTC_1224_SY);
        assertApproxEqRel(outAmount, 1.9698e8, REL_PRECISION);
        assertApproxEqRel(outAmount1000, outAmount * 1000, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_EBTC_1224_SY, PENDLE_EBTC_1224_MARKET);
        assertApproxEqRel(outAmountInv, 1e18, REL_PRECISION);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, PENDLE_EBTC_1224_SY, PENDLE_EBTC_1224_MARKET);
        assertApproxEqRel(outAmountInv1000, 1000e18, REL_PRECISION);
    }

    /// @dev This market is active. 1 LP-eBTC1224 = 1.9836 eBTC.
    function test_GetQuote_ActiveMarket_eBTC1224_LP_Asset() public {
        PendleUniversalOracle oracle =
            new PendleUniversalOracle(PENDLE_ORACLE, PENDLE_EBTC_1224_MARKET, PENDLE_EBTC_1224_MARKET, EBTC, 15 minutes);

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EBTC_1224_MARKET, EBTC);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_EBTC_1224_MARKET, EBTC);
        assertApproxEqRel(outAmount, 1.9836e8, REL_PRECISION);
        assertApproxEqRel(outAmount1000, outAmount * 1000, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, EBTC, PENDLE_EBTC_1224_MARKET);
        assertApproxEqRel(outAmountInv, 1e18, REL_PRECISION);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, EBTC, PENDLE_EBTC_1224_MARKET);
        assertApproxEqRel(outAmountInv1000, 1000e18, REL_PRECISION);
    }

    /// @dev This market is active. 1 PT-LBTC1224 = 0.9802 SY-LBTC. Oracle has no slippage.
    function test_GetQuote_ActiveMarket_LBTC1224_PT_SY() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_CORN_LBTC_1224_MARKET, PENDLE_CORN_LBTC_1224_PT, PENDLE_CORN_LBTC_1224_SY, 15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_CORN_LBTC_1224_PT, PENDLE_CORN_LBTC_1224_SY);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_CORN_LBTC_1224_PT, PENDLE_CORN_LBTC_1224_SY);
        assertApproxEqRel(outAmount, 0.9802e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_CORN_LBTC_1224_SY, PENDLE_CORN_LBTC_1224_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, PENDLE_CORN_LBTC_1224_SY, PENDLE_CORN_LBTC_1224_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 PT-LBTC1224 = 0.9802 WBTC. Oracle has no slippage.
    function test_GetQuote_ActiveMarket_LBTC1224_PT_Asset() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_CORN_LBTC_1224_MARKET, PENDLE_CORN_LBTC_1224_PT, WBTC, 15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_CORN_LBTC_1224_PT, WBTC);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_CORN_LBTC_1224_PT, WBTC);
        assertApproxEqRel(outAmount, 0.9802e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, WBTC, PENDLE_CORN_LBTC_1224_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, WBTC, PENDLE_CORN_LBTC_1224_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 LP-LBTC1224 = 2.0775 SY-LBTC.
    function test_GetQuote_ActiveMarket_LBTC1224_LP_SY() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE,
            PENDLE_CORN_LBTC_1224_MARKET,
            PENDLE_CORN_LBTC_1224_MARKET,
            PENDLE_CORN_LBTC_1224_SY,
            15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_CORN_LBTC_1224_MARKET, PENDLE_CORN_LBTC_1224_SY);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_CORN_LBTC_1224_MARKET, PENDLE_CORN_LBTC_1224_SY);
        assertApproxEqRel(outAmount, 2.0775e8, REL_PRECISION);
        assertApproxEqRel(outAmount1000, outAmount * 1000, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_CORN_LBTC_1224_SY, PENDLE_CORN_LBTC_1224_MARKET);
        assertApproxEqRel(outAmountInv, 1e18, REL_PRECISION);
        uint256 outAmountInv1000 =
            oracle.getQuote(outAmount1000, PENDLE_CORN_LBTC_1224_SY, PENDLE_CORN_LBTC_1224_MARKET);
        assertApproxEqRel(outAmountInv1000, 1000e18, REL_PRECISION);
    }

    /// @dev This market is active. 1 LP-LBTC1224 = 2.0775 WBTC.
    function test_GetQuote_ActiveMarket_LBTC1224_LP_Asset() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_CORN_LBTC_1224_MARKET, PENDLE_CORN_LBTC_1224_MARKET, WBTC, 15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_CORN_LBTC_1224_MARKET, WBTC);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_CORN_LBTC_1224_MARKET, WBTC);
        assertApproxEqRel(outAmount, 2.0775e8, REL_PRECISION);
        assertApproxEqRel(outAmount1000, outAmount * 1000, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, WBTC, PENDLE_CORN_LBTC_1224_MARKET);
        assertApproxEqRel(outAmountInv, 1e18, REL_PRECISION);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, WBTC, PENDLE_CORN_LBTC_1224_MARKET);
        assertApproxEqRel(outAmountInv1000, 1000e18, REL_PRECISION);
    }

    /// @dev This market has expired, so 1 PT = 0.95712 SY-weETH without slippage.
    function test_GetQuote_ExpiredMarket_eETH0624_PT_SY() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, PENDLE_EETH_0624_PT, PENDLE_EETH_0624_SY, 15 minutes
        );
        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EETH_0624_PT, PENDLE_EETH_0624_SY);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_EETH_0624_PT, PENDLE_EETH_0624_SY);
        assertApproxEqRel(outAmount, 0.95712e18, REL_PRECISION);
        assertApproxEqRel(outAmount1000, 0.95712e18 * 1000, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_EETH_0624_SY, PENDLE_EETH_0624_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, PENDLE_EETH_0624_SY, PENDLE_EETH_0624_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market has expired, so 1 PT = 1 eETH without slippage.
    function test_GetQuote_ExpiredMarket_eETH0624_PT_Asset() public {
        PendleUniversalOracle oracle =
            new PendleUniversalOracle(PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, PENDLE_EETH_0624_PT, EETH, 15 minutes);
        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EETH_0624_PT, EETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_EETH_0624_PT, EETH);
        assertEq(outAmount, 1e18);
        assertEq(outAmount1000, 1000e18);

        uint256 outAmountInv = oracle.getQuote(outAmount, EETH, PENDLE_EETH_0624_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, EETH, PENDLE_EETH_0624_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market has expired, so 1 LP = 2.0058 SY-weETH without slippage.
    function test_GetQuote_ExpiredMarket_eETH0624_LP_SY() public {
        PendleUniversalOracle oracle = new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, PENDLE_EETH_0624_MARKET, PENDLE_EETH_0624_SY, 15 minutes
        );
        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EETH_0624_MARKET, PENDLE_EETH_0624_SY);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_EETH_0624_MARKET, PENDLE_EETH_0624_SY);
        assertApproxEqRel(outAmount, 2.0058e18, REL_PRECISION);
        assertApproxEqRel(outAmount1000, 2.0058e18 * 1000, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_EETH_0624_SY, PENDLE_EETH_0624_MARKET);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, PENDLE_EETH_0624_SY, PENDLE_EETH_0624_MARKET);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market has expired, so 1 LP = 2.1031 eETH without slippage.
    function test_GetQuote_ExpiredMarket_eETH0624_LP_Asset() public {
        PendleUniversalOracle oracle =
            new PendleUniversalOracle(PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, PENDLE_EETH_0624_MARKET, EETH, 15 minutes);
        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EETH_0624_MARKET, EETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_EETH_0624_MARKET, EETH);
        assertApproxEqRel(outAmount, 2.1031e18, REL_PRECISION);
        assertApproxEqRel(outAmount1000, 2.1031e18 * 1000, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, EETH, PENDLE_EETH_0624_MARKET);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, EETH, PENDLE_EETH_0624_MARKET);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market's oracle buffer is not initialized, so deployment should revert.
    function test_Constructor_OracleBufferNotInitialized() public {
        // Oracle does not support 15 minutes.
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_STETH_0323_MARKET, PENDLE_STETH_0323_PT, PENDLE_STETH_0323_SY, 900
        );
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new PendleUniversalOracle(PENDLE_ORACLE, PENDLE_STETH_0323_MARKET, PENDLE_STETH_0323_PT, USDE, 900);

        // Oracle does not support 5 minutes.
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new PendleUniversalOracle(
            PENDLE_ORACLE, PENDLE_STETH_0323_MARKET, PENDLE_STETH_0323_PT, PENDLE_STETH_0323_SY, 300
        );
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new PendleUniversalOracle(PENDLE_ORACLE, PENDLE_STETH_0323_MARKET, PENDLE_STETH_0323_PT, USDE, 900);
    }
}
