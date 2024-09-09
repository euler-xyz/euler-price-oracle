// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {WSTETH, EZETH, WETH, USDC, USD, WBTC, BTC} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {FixedRateOracle} from "src/adapter/fixed/FixedRateOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract FixedRateOracleForkTest is ForkTest {
    function setUp() public {
        _setUpFork();
    }

    function test_Constructor_Integrity() public {
        FixedRateOracle oracle = new FixedRateOracle(WSTETH, WETH, 1.2e18);
        assertEq(oracle.base(), WSTETH);
        assertEq(oracle.quote(), WETH);
        assertEq(oracle.rate(), 1.2e18);
    }

    function test_GetQuote_wstETH() public {
        uint256 rate = 1.2e18;
        FixedRateOracle oracle = new FixedRateOracle(WSTETH, WETH, rate);

        uint256 outAmount = oracle.getQuote(1e18, WSTETH, WETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, WSTETH, WETH);
        assertEq(outAmount, rate);
        assertEq(outAmount1000, rate * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, WETH, WSTETH);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, WETH, WSTETH);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_USDC() public {
        uint256 rate = 1.2e18;
        FixedRateOracle oracle = new FixedRateOracle(USDC, USD, rate);

        uint256 outAmount = oracle.getQuote(1e6, USDC, USD);
        uint256 outAmount1000 = oracle.getQuote(1000e6, USDC, USD);
        assertEq(outAmount, rate);
        assertEq(outAmount1000, rate * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USD, USDC);
        assertEq(outAmountInv, 1e6);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USD, USDC);
        assertEq(outAmountInv1000, 1000e6);
    }

    function test_GetQuote_WBTC() public {
        uint256 rate = 0.95e8;
        FixedRateOracle oracle = new FixedRateOracle(BTC, WBTC, rate);

        uint256 outAmount = oracle.getQuote(1e18, BTC, WBTC);
        uint256 outAmount1000 = oracle.getQuote(1000e18, BTC, WBTC);
        assertEq(outAmount, rate);
        assertEq(outAmount1000, rate * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, WBTC, BTC);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, WBTC, BTC);
        assertEq(outAmountInv1000, 1000e18);
    }
}
