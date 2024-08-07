// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {
    PENDLE_ORACLE,
    PENDLE_EETH_0624_MARKET,
    PENDLE_EETH_0624_PT,
    PENDLE_EETH_0624_SY,
    PENDLE_STETH_1227_MARKET,
    PENDLE_STETH_1227_PT,
    PENDLE_STETH_1227_SY,
    PENDLE_SUSDE_0924_MARKET,
    PENDLE_SUSDE_0924_PT,
    PENDLE_SUSDE_0924_SY
} from "test/adapter/pendle/PendleAddresses.sol";
import {EETH, USDC, USDE} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {PendleOracle} from "src/adapter/pendle/PendleOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract PendleOracleForkTest is ForkTest {
    /// @dev 1%
    uint256 constant REL_PRECISION = 0.01e18;

    function setUp() public {
        _setUpFork(20475432);
    }

    function test_Constructor_Integrity() public {
        PendleOracle oracle = new PendleOracle(
            PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, PENDLE_EETH_0624_PT, PENDLE_EETH_0624_SY, 15 minutes
        );
        assertEq(oracle.pendleMarket(), PENDLE_EETH_0624_MARKET);
        assertEq(oracle.twapWindow(), 15 minutes);
        assertEq(oracle.base(), PENDLE_EETH_0624_PT);
        assertEq(oracle.quote(), PENDLE_EETH_0624_SY);
    }

    /// @dev This market is active. 1 PT-sUSDe0924 = 0.8931 sUSDe. Oracle has no slippage.
    function test_GetQuote_ActiveMarket_sUSDe0924_PT_SY() public {
        PendleOracle oracle = new PendleOracle(
            PENDLE_ORACLE, PENDLE_SUSDE_0924_MARKET, PENDLE_SUSDE_0924_PT, PENDLE_SUSDE_0924_SY, 15 minutes
        );

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_SUSDE_0924_PT, PENDLE_SUSDE_0924_SY);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_SUSDE_0924_PT, PENDLE_SUSDE_0924_SY);
        assertApproxEqRel(outAmount, 0.8931e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_SUSDE_0924_SY, PENDLE_SUSDE_0924_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, PENDLE_SUSDE_0924_SY, PENDLE_SUSDE_0924_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market is active. 1 PT-sUSDe0924 = 0.9727 USDe. Oracle has no slippage.
    function test_GetQuote_ActiveMarket_sUSDe0924_PT_Asset() public {
        PendleOracle oracle =
            new PendleOracle(PENDLE_ORACLE, PENDLE_SUSDE_0924_MARKET, PENDLE_SUSDE_0924_PT, USDE, 15 minutes);

        uint256 outAmount = oracle.getQuote(1e18, PENDLE_SUSDE_0924_PT, USDE);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_SUSDE_0924_PT, USDE);
        assertApproxEqRel(outAmount, 0.9727e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDE, PENDLE_SUSDE_0924_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USDE, PENDLE_SUSDE_0924_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market has expired, so 1 PT = 0.95712 weETH without slippage.
    function test_GetQuote_ExpiredMarket_eETH0624_PT_SY() public {
        PendleOracle oracle = new PendleOracle(
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

    /// @dev This market has expired, so 1 PT = 1 eETHH without slippage.
    function test_GetQuote_ExpiredMarket_eETH0624_PT_Asset() public {
        PendleOracle oracle =
            new PendleOracle(PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, PENDLE_EETH_0624_PT, EETH, 15 minutes);
        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EETH_0624_PT, EETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, PENDLE_EETH_0624_PT, EETH);
        assertEq(outAmount, 1e18);
        assertEq(outAmount1000, 1000e18);

        uint256 outAmountInv = oracle.getQuote(outAmount, EETH, PENDLE_EETH_0624_PT);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, EETH, PENDLE_EETH_0624_PT);
        assertEq(outAmountInv1000, 1000e18);
    }

    /// @dev This market's oracle buffer is not initialized, so deployment should revert.
    function test_Constructor_OracleBufferNotInitialized() public {
        // Oracle does not support 15 minutes.
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new PendleOracle(PENDLE_ORACLE, PENDLE_STETH_1227_MARKET, PENDLE_STETH_1227_PT, PENDLE_STETH_1227_SY, 900);
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new PendleOracle(PENDLE_ORACLE, PENDLE_STETH_1227_MARKET, PENDLE_STETH_1227_PT, USDE, 900);

        // Oracle does not support 5 minutes.
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new PendleOracle(PENDLE_ORACLE, PENDLE_STETH_1227_MARKET, PENDLE_STETH_1227_PT, PENDLE_STETH_1227_SY, 300);
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new PendleOracle(PENDLE_ORACLE, PENDLE_STETH_1227_MARKET, PENDLE_STETH_1227_PT, USDE, 900);
    }
}
