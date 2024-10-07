// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {BALANCER_RETH_RATE_PROVIDER, BALANCER_WEETH_RATE_PROVIDER} from "test/adapter/rate/RateProviderAddresses.sol";
import {RETH, WEETH, WETH, WSTETH} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {LidoFundamentalOracle} from "src/adapter/lido/LidoFundamentalOracle.sol";
import {RateProviderOracle} from "src/adapter/rate/RateProviderOracle.sol";
import {GrowthSentinel} from "src/wrapper/GrowthSentinel.sol";

contract GrowthSentinelForkTest is ForkTest {
    function setUp() public {
        _setUpFork(20893573);
    }

    function test_wstETH() public {
        vm.rollFork(12000000);
        LidoFundamentalOracle adapter = new LidoFundamentalOracle();
        uint256 maxRateGrowth = uint256(0.08e18) / 365 days;
        GrowthSentinel sentinel = new GrowthSentinel(address(adapter), WSTETH, WETH, maxRateGrowth);

        vm.rollFork(20893573);
        uint256 adapterOutAmount = adapter.getQuote(1e18, WSTETH, WETH);
        uint256 sentinelOutAmount = sentinel.getQuote(1e18, WSTETH, WETH);
        assertEq(sentinelOutAmount, adapterOutAmount);
    }

    function test_rETH() public {
        vm.rollFork(13846103);
        RateProviderOracle adapter = new RateProviderOracle(RETH, WETH, BALANCER_RETH_RATE_PROVIDER);
        uint256 maxRateGrowth = uint256(0.08e18) / 365 days;
        GrowthSentinel sentinel = new GrowthSentinel(address(adapter), RETH, WETH, maxRateGrowth);

        vm.rollFork(20893573);
        uint256 adapterOutAmount = adapter.getQuote(1e18, RETH, WETH);
        uint256 sentinelOutAmount = sentinel.getQuote(1e18, RETH, WETH);
        assertEq(sentinelOutAmount, adapterOutAmount);
    }

    function test_weETH() public {
        vm.rollFork(18550000);
        RateProviderOracle adapter = new RateProviderOracle(WEETH, WETH, BALANCER_WEETH_RATE_PROVIDER);
        uint256 maxRateGrowth = uint256(0.08e18) / 365 days;
        GrowthSentinel sentinel = new GrowthSentinel(address(adapter), WEETH, WETH, maxRateGrowth);

        vm.rollFork(20893573);
        uint256 adapterOutAmount = adapter.getQuote(1e18, WEETH, WETH);
        uint256 sentinelOutAmount = sentinel.getQuote(1e18, WEETH, WETH);
        assertEq(sentinelOutAmount, adapterOutAmount);
    }
}
