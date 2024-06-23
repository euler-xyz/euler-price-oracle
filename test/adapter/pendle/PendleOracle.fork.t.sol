// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {
    PENDLE_ORACLE,
    PENDLE_EETH_0624_MARKET,
    PENDLE_EETH_0624_PT,
    PENDLE_EETH_0624_SY,
    PENDLE_EETH_0624_YT,
    PENDLE_FUSDC_1224_MARKET,
    PENDLE_FUSDC_1224_PT,
    PENDLE_FUSDC_1224_SY,
    PENDLE_FUSDC_1224_YT
} from "test/adapter/pendle/PendleAddresses.sol";
import {EETH, USDC} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {PendleOracle} from "src/adapter/pendle/PendleOracle.sol";

contract PendleOracleForkTest is ForkTest {
    function setUp() public {
        _setUpFork(20153426);
    }

    function test_Constructor_Integrity() public {
        PendleOracle oracle =
            new PendleOracle(PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, 15 minutes, PendleOracle.OraclePair.PT_SY);
        assertEq(oracle.pendleMarket(), PENDLE_EETH_0624_MARKET);
        assertEq(oracle.twapWindow(), 15 minutes);
        assertEq(oracle.base(), PENDLE_EETH_0624_PT);
        assertEq(oracle.quote(), PENDLE_EETH_0624_SY);
    }

    function test_GetQuote_eETH0624_PT_SY() public {
        PendleOracle oracle =
            new PendleOracle(PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, 15 minutes, PendleOracle.OraclePair.PT_SY);
        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EETH_0624_PT, PENDLE_EETH_0624_SY);
        assertLt(outAmount, 1e18);
        assertGt(outAmount, 0.95e18);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_EETH_0624_SY, PENDLE_EETH_0624_PT);
        assertApproxEqRel(outAmountInv, 1e18, 1e9);
    }

    function test_GetQuote_eETH0624_PT_Asset() public {
        PendleOracle oracle =
            new PendleOracle(PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, 15 minutes, PendleOracle.OraclePair.PT_ASSET);
        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EETH_0624_PT, EETH);
        assertLt(outAmount, 1e18);
        assertGt(outAmount, 0.99e18);

        uint256 outAmountInv = oracle.getQuote(outAmount, EETH, PENDLE_EETH_0624_PT);
        assertApproxEqRel(outAmountInv, 1e18, 1e9);
    }

    function test_GetQuote_eETH0624_YT_SY() public {
        PendleOracle oracle =
            new PendleOracle(PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, 15 minutes, PendleOracle.OraclePair.YT_SY);
        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EETH_0624_YT, PENDLE_EETH_0624_SY);
        assertLt(outAmount, 0.01e18);
        assertGt(outAmount, 0);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_EETH_0624_SY, PENDLE_EETH_0624_YT);
        assertApproxEqRel(outAmountInv, 1e18, 1e9);
    }

    function test_GetQuote_eETH0624_YT_Asset() public {
        PendleOracle oracle =
            new PendleOracle(PENDLE_ORACLE, PENDLE_EETH_0624_MARKET, 15 minutes, PendleOracle.OraclePair.YT_ASSET);
        uint256 outAmount = oracle.getQuote(1e18, PENDLE_EETH_0624_YT, EETH);
        assertLt(outAmount, 0.01e18);
        assertGt(outAmount, 0);

        uint256 outAmountInv = oracle.getQuote(outAmount, EETH, PENDLE_EETH_0624_YT);
        assertApproxEqRel(outAmountInv, 1e18, 1e9);
    }

    function test_GetQuote_fUSDC1224_PT_SY() public {
        vm.skip(true);
        PendleOracle oracle =
            new PendleOracle(PENDLE_ORACLE, PENDLE_FUSDC_1224_MARKET, 15 minutes, PendleOracle.OraclePair.PT_SY);
        uint256 outAmount = oracle.getQuote(1e6, PENDLE_FUSDC_1224_PT, PENDLE_FUSDC_1224_SY);
        assertLt(outAmount, 45e8);
        // assertGt(outAmount, 0.95e6);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_FUSDC_1224_SY, PENDLE_FUSDC_1224_PT);
        assertApproxEqRel(outAmountInv, 1e6, 1e15);
    }

    function test_GetQuote_fUSDC1224_PT_Asset() public {
        vm.skip(true);
        PendleOracle oracle =
            new PendleOracle(PENDLE_ORACLE, PENDLE_FUSDC_1224_MARKET, 15 minutes, PendleOracle.OraclePair.PT_ASSET);
        uint256 outAmount = oracle.getQuote(1e6, PENDLE_FUSDC_1224_PT, USDC);
        assertLt(outAmount, 1e6);
        assertGt(outAmount, 0.95e6);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDC, PENDLE_FUSDC_1224_PT);
        assertApproxEqRel(outAmountInv, 1e6, 1e15);
    }

    function test_GetQuote_fUSDC1224_YT_SY() public {
        vm.skip(true);
        PendleOracle oracle =
            new PendleOracle(PENDLE_ORACLE, PENDLE_FUSDC_1224_MARKET, 15 minutes, PendleOracle.OraclePair.YT_SY);
        uint256 outAmount = oracle.getQuote(1e18, PENDLE_FUSDC_1224_YT, PENDLE_FUSDC_1224_SY);
        assertLt(outAmount, 0.01e18);
        assertGt(outAmount, 0);

        uint256 outAmountInv = oracle.getQuote(outAmount, PENDLE_FUSDC_1224_SY, PENDLE_FUSDC_1224_YT);
        assertApproxEqRel(outAmountInv, 1e18, 1e9);
    }

    function test_GetQuote_fUSDC1224_Asset() public {
        vm.skip(true);
        PendleOracle oracle =
            new PendleOracle(PENDLE_ORACLE, PENDLE_FUSDC_1224_MARKET, 15 minutes, PendleOracle.OraclePair.YT_ASSET);
        uint256 outAmount = oracle.getQuote(1e18, PENDLE_FUSDC_1224_YT, USDC);
        assertLt(outAmount, 0.01e18);
        assertGt(outAmount, 0);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDC, PENDLE_FUSDC_1224_YT);
        assertApproxEqRel(outAmountInv, 1e18, 1e9);
    }
}
