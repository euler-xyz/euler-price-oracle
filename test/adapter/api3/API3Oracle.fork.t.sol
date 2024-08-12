// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ForkTest} from "test/utils/ForkTest.sol";
import {
    API3_ARBITRUM_ETH_USD_FEED,
    API3_ARBITRUM_ETHX_ETH_FEED,
    API3_ARBITRUM_USDC_USD_FEED
} from "test/adapter/api3/API3Addresses.sol";
import {ETHX, USD, USDC, WETH} from "test/utils/ArbitrumAddresses.sol";
import {API3Oracle} from "src/adapter/api3/API3Oracle.sol";

contract API3OracleForkTest is ForkTest {
    API3Oracle oracle;

    function setUp() public {
        _setUpArbitrumFork(242146132);
    }

    function test_ethUsd() public {
        oracle = new API3Oracle(WETH, USD, API3_ARBITRUM_ETH_USD_FEED, 24 hours);
        assertApproxEqRel(oracle.getQuote(1e18, WETH, USD), 2680e18, 0.1e18);
        assertApproxEqRel(oracle.getQuote(2680e18, USD, WETH), 1e18, 0.1e18);
    }

    function test_ethxEth() public {
        oracle = new API3Oracle(ETHX, WETH, API3_ARBITRUM_ETHX_ETH_FEED, 24 hours);
        assertApproxEqRel(oracle.getQuote(1e18, ETHX, WETH), 1.0374e18, 0.001e18);
        assertApproxEqRel(oracle.getQuote(1.0374e18, WETH, ETHX), 1e18, 0.001e18);
    }

    function test_usdcUsd() public {
        oracle = new API3Oracle(USDC, USD, API3_ARBITRUM_USDC_USD_FEED, 24 hours);
        assertApproxEqRel(oracle.getQuote(1000e6, USDC, USD), 1000e18, 0.01e18);
        assertApproxEqRel(oracle.getQuote(1000e18, USD, USDC), 1000e6, 0.01e18);
    }
}
