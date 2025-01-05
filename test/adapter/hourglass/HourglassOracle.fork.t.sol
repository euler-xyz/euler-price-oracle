// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// ============ Imports ============

// Foundry's base test that sets up a mainnet or testnet fork
import {ForkTest} from "test/utils/ForkTest.sol";

// Import your HourglassOracle
import {HourglassOracle} from "src/adapter/hourglass/HourglassOracle.sol";
import {Errors} from "src/lib/Errors.sol";

// Typically you'd import ERC20 or an interface to check balances if needed
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {
    HOURGLASS_LBTCV_01MAR2025_DEPOSITOR, 
    HOURGLASS_LBTCV_01MAR2025_PT, 
    HOURGLASS_LBTCV_01MAR2025_CT, 
    HOURGLASS_LBTCV_01MAR2025_UNDERLYING, 
    HOURGLASS_LBTCV_01DEC2024_DEPOSITOR, 
    HOURGLASS_LBTCV_01DEC2024_PT, 
    HOURGLASS_LBTCV_01DEC2024_UNDERLYING
} from "test/adapter/hourglass/HourglassAddresses.sol";

/**
 * @dev Example discountRate as "per-second" rate in 1e18 form. For instance:
 * - 100% annual ~ 3.17e10 if you do (1.0 / 31536000) * 1e18
 * - 50% annual ~ 1.585e10
 * - Adjust to whatever you want for testing
 */
uint256 constant DISCOUNT_RATE_PER_SECOND = 1585489599; // ~ 5% annual

contract HourglassOracleForkTest is ForkTest {
    // For relative assert precision (e.g. 1% = 0.01e18)
    uint256 constant REL_PRECISION = 0.01e18;

    /**
     * @dev Choose a block where the Hourglass depositor, PT, CT, etc. are deployed
     *      and in a known state. Adjust as needed.
     */
    function setUp() public {
        _setUpFork(21_400_000); // Dec-14-2024 09:56:47 AM +UTC
    }

    /**
     * @dev Basic constructor test: deploy HourglassOracle with the PT as 'base'
     * and the "underlying" (or CT, whichever is correct in your design) as 'quote'.
     */
    function test_Constructor_Integrity_Hourglass() public {
        HourglassOracle oracle = new HourglassOracle(
            HOURGLASS_LBTCV_01MAR2025_PT,         // base
            HOURGLASS_LBTCV_01MAR2025_UNDERLYING, // quote
            DISCOUNT_RATE_PER_SECOND              // discount rate
        );

        // The contract returns "HourglassOracle"
        assertEq(oracle.name(), "HourglassOracle");

        // The base/quote we passed in
        assertEq(oracle.base(),  HOURGLASS_LBTCV_01MAR2025_PT);
        assertEq(oracle.quote(), HOURGLASS_LBTCV_01MAR2025_UNDERLYING);

        // The discountRate we provided
        assertEq(oracle.discountRate(), DISCOUNT_RATE_PER_SECOND);

        // You could also check that the "depositor" is set as expected:
        // e.g. (from inside your HourglassOracle) "hourglassDepositor"
        // But you only can do that if it's public or there's a getter.
        // e.g., if hourglassDepositor is public:
        assertEq(address(oracle.hourglassDepositor()), HOURGLASS_LBTCV_01MAR2025_DEPOSITOR);
    }

    /**
     * @dev Example "active market" test - calls getQuote() both ways (PT -> underlying, and underlying -> PT).
     * This is analogous to your Pendle tests where you check the rate with no slippage,
     * but you need to know what 1 PT is expected to be in "underlying" at this block.
     */
    function test_GetQuote_ActiveMarket_LBTCV_01MAR2025_PT() public {
        // Deploy the oracle
        HourglassOracle oracle = new HourglassOracle(
            HOURGLASS_LBTCV_01MAR2025_PT,         // base
            HOURGLASS_LBTCV_01MAR2025_UNDERLYING, // quote
            DISCOUNT_RATE_PER_SECOND
        );

        // PT -> underlying
        uint256 outAmount = oracle.getQuote(1e8, HOURGLASS_LBTCV_01MAR2025_PT, HOURGLASS_LBTCV_01MAR2025_UNDERLYING);
        assertApproxEqRel(outAmount, 0.99707e8, REL_PRECISION);

        // Underlying -> PT
        uint256 outAmountInv = oracle.getQuote(outAmount, HOURGLASS_LBTCV_01MAR2025_UNDERLYING, HOURGLASS_LBTCV_01MAR2025_PT);
        assertApproxEqRel(outAmountInv, 1e8, REL_PRECISION);
    }

        /**
     * @dev Example "active market" test - calls getQuote() both ways (CT -> underlying, and underlying -> CT).
     * This is analogous to your Pendle tests where you check the rate with no slippage,
     * but you need to know what 1 CT is expected to be in "underlying" at this block.
     */
    function test_GetQuote_ActiveMarket_LBTCV_01MAR2025_CT() public {
        // Deploy the oracle
        HourglassOracle oracle = new HourglassOracle(
            HOURGLASS_LBTCV_01MAR2025_CT,         // base
            HOURGLASS_LBTCV_01MAR2025_UNDERLYING, // quote
            DISCOUNT_RATE_PER_SECOND
        );

        // PT -> underlying
        uint256 outAmount = oracle.getQuote(1e8, HOURGLASS_LBTCV_01MAR2025_CT, HOURGLASS_LBTCV_01MAR2025_UNDERLYING);
        assertApproxEqRel(outAmount, 0.99707e8, REL_PRECISION);

        // Underlying -> PT
        uint256 outAmountInv = oracle.getQuote(outAmount, HOURGLASS_LBTCV_01MAR2025_UNDERLYING, HOURGLASS_LBTCV_01MAR2025_CT);
        assertApproxEqRel(outAmountInv, 1e8, REL_PRECISION);
    }

    /**
     * @dev Example "expired market" test. If your hourglass PT has matured by the fork block,
     * then 1 PT might fully be worth exactly 1 underlying, or some final settled ratio.
     */
    function test_GetQuote_ExpiredMarket() public {
        // If the market for LBTCV_01MAR2025 is expired at the chosen block, you can test that 1 PT = 1 underlying
        // or whatever the final settlement is.
        HourglassOracle oracle = new HourglassOracle(
            HOURGLASS_LBTCV_01DEC2024_PT,
            HOURGLASS_LBTCV_01DEC2024_UNDERLYING,
            DISCOUNT_RATE_PER_SECOND
        );

        uint256 outAmount = oracle.getQuote(1e8, HOURGLASS_LBTCV_01DEC2024_PT, HOURGLASS_LBTCV_01DEC2024_UNDERLYING);
        assertEq(outAmount, 1e8);
    }

    /**
     * @dev If you expect invalid configuration (like discountRate=0 or base=quote, etc.),
     * you can test that your HourglassOracle reverts.
     */
    function test_Constructor_InvalidConfiguration() public {
        // For example, discountRate = 0 => revert PriceOracle_InvalidConfiguration
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        new HourglassOracle(
            HOURGLASS_LBTCV_01MAR2025_PT,
            HOURGLASS_LBTCV_01MAR2025_UNDERLYING,
            0 // zero discount => revert
        );
    }
}