// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {StubPriceOracle} from "test/adapter/StubPriceOracle.sol";
import {RateGrowthSentinel} from "src/wrapper/RateGrowthSentinel.sol";

contract RateGrowthSentinelTest is Test {
    address base = makeAddr("BASE");
    address quote = makeAddr("QUOTE");
    uint256 maxGrowthPerSecond = 0.1e18;
    StubPriceOracle wrappedAdapter;
    RateGrowthSentinel sentinel;

    function setUp() public {
        vm.warp(0);
        wrappedAdapter = new StubPriceOracle();
        vm.mockCall(base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(18));
        vm.mockCall(quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(18));
        wrappedAdapter.setPrice(base, quote, 1e18);
        sentinel = new RateGrowthSentinel(address(wrappedAdapter), base, quote, maxGrowthPerSecond);
    }

    function test_Quote_NoIncrease() public view {
        uint256 sentinelOutAmount = sentinel.getQuote(60e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(60e18, base, quote);
        assertEq(sentinelOutAmount, adapterOutAmount);

        sentinelOutAmount = sentinel.getQuote(60e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(60e18, quote, base);
        assertEq(sentinelOutAmount, adapterOutAmount);
    }

    function test_Quote_IncreaseUnderMaxGrowth() public {
        vm.warp(10);
        wrappedAdapter.setPrice(base, quote, 1e18 + maxGrowthPerSecond * 10);

        uint256 sentinelOutAmount = sentinel.getQuote(60e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(60e18, base, quote);
        assertEq(sentinelOutAmount, adapterOutAmount);

        sentinelOutAmount = sentinel.getQuote(60e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(60e18, quote, base);
        assertEq(sentinelOutAmount, adapterOutAmount);
    }

    function test_Quote_IncreaseOverMaxGrowth() public {
        vm.warp(10);
        wrappedAdapter.setPrice(base, quote, 5e18);

        uint256 sentinelOutAmount = sentinel.getQuote(1e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(1e18, base, quote);

        assertEq(sentinelOutAmount, 2e18);
        assertEq(adapterOutAmount, 5e18);

        sentinelOutAmount = sentinel.getQuote(1e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(1e18, quote, base);
        assertEq(sentinelOutAmount, 0.2e18);
        assertEq(adapterOutAmount, 0.2e18);
    }
}
