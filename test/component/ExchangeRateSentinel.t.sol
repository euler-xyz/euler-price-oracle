// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {StubPriceOracle} from "test/adapter/StubPriceOracle.sol";
import {ExchangeRateSentinel} from "src/component/ExchangeRateSentinel.sol";

contract ExchangeRateSentinelTest is Test {
    address base = makeAddr("BASE");
    address quote = makeAddr("QUOTE");
    uint256 INITIAL_RATE = 2e18;
    uint256 MAX_RATE_GROWTH = 0.1e18;
    uint256 FLOOR_RATE = 1e18;
    uint256 CEIL_RATE = 5e18;
    StubPriceOracle wrappedAdapter;
    ExchangeRateSentinel sentinel;

    function setUp() public {
        vm.warp(0);
        wrappedAdapter = new StubPriceOracle();
        vm.mockCall(base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(18));
        vm.mockCall(quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(18));
        setPrice(INITIAL_RATE);
        sentinel =
            new ExchangeRateSentinel(address(wrappedAdapter), base, quote, FLOOR_RATE, CEIL_RATE, MAX_RATE_GROWTH);
    }

    function test_Quote_GrowthBoundsDisabled() public {
        sentinel =
            new ExchangeRateSentinel(address(wrappedAdapter), base, quote, FLOOR_RATE, CEIL_RATE, type(uint256).max);

        vm.warp(10);
        setPrice(CEIL_RATE);

        uint256 sentinelOutAmount = sentinel.getQuote(1e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(1e18, base, quote);
        assertEq(sentinelOutAmount, CEIL_RATE);
        assertEq(adapterOutAmount, CEIL_RATE);

        sentinelOutAmount = sentinel.getQuote(1e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(1e18, quote, base);
        assertEq(sentinelOutAmount, 1e36 / CEIL_RATE);
        assertEq(adapterOutAmount, 1e36 / CEIL_RATE);
    }

    function test_Quote_AtInitial() public {
        vm.warp(10);
        setPrice(INITIAL_RATE);

        uint256 sentinelOutAmount = sentinel.getQuote(1e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(1e18, base, quote);
        assertEq(sentinelOutAmount, INITIAL_RATE);
        assertEq(adapterOutAmount, INITIAL_RATE);

        sentinelOutAmount = sentinel.getQuote(1e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(1e18, quote, base);
        assertEq(sentinelOutAmount, 1e36 / INITIAL_RATE);
        assertEq(adapterOutAmount, 1e36 / INITIAL_RATE);
    }

    function test_Quote_AtFloor() public {
        vm.warp(10);
        setPrice(FLOOR_RATE);

        uint256 sentinelOutAmount = sentinel.getQuote(1e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(1e18, base, quote);
        assertEq(sentinelOutAmount, FLOOR_RATE);
        assertEq(adapterOutAmount, FLOOR_RATE);

        sentinelOutAmount = sentinel.getQuote(1e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(1e18, quote, base);
        assertEq(sentinelOutAmount, 1e36 / FLOOR_RATE);
        assertEq(adapterOutAmount, 1e36 / FLOOR_RATE);
    }

    function test_Quote_BelowFloor() public {
        vm.warp(10);
        setPrice(0.5e18);

        uint256 sentinelOutAmount = sentinel.getQuote(1e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(1e18, base, quote);
        assertEq(sentinelOutAmount, FLOOR_RATE);
        assertEq(adapterOutAmount, 0.5e18);

        sentinelOutAmount = sentinel.getQuote(1e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(1e18, quote, base);
        assertEq(sentinelOutAmount, 1e36 / FLOOR_RATE);
        assertEq(adapterOutAmount, 1e36 / 0.5e18);
    }

    function test_Quote_IncreaseAtMaxGrowth() public {
        vm.warp(10);
        uint256 price = INITIAL_RATE + MAX_RATE_GROWTH * 10;
        setPrice(price);

        uint256 sentinelOutAmount = sentinel.getQuote(1e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(1e18, base, quote);
        assertEq(sentinelOutAmount, price);
        assertEq(adapterOutAmount, price);

        sentinelOutAmount = sentinel.getQuote(1e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(1e18, quote, base);
        assertEq(sentinelOutAmount, 1e36 / price);
        assertEq(adapterOutAmount, 1e36 / price);
    }

    function test_Quote_IncreaseOverMaxGrowthUnderCeil() public {
        vm.warp(20);
        uint256 price = 4e18;
        setPrice(price);
        uint256 maxPrice = INITIAL_RATE + MAX_RATE_GROWTH * 20;
        assertEq(sentinel.maxRate(), maxPrice);

        uint256 sentinelOutAmount = sentinel.getQuote(1e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(1e18, base, quote);

        assertEq(sentinelOutAmount, maxPrice);
        assertEq(adapterOutAmount, price);

        sentinelOutAmount = sentinel.getQuote(1e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(1e18, quote, base);
        assertEq(sentinelOutAmount, 1e36 / maxPrice);
        assertEq(adapterOutAmount, 1e36 / price);
    }

    function test_Quote_IncreaseOverMaxGrowthAtCeil() public {
        vm.warp(30);
        uint256 price = 5e18;
        setPrice(price);
        uint256 maxPrice = INITIAL_RATE + MAX_RATE_GROWTH * 30;
        assertEq(sentinel.maxRate(), maxPrice);

        uint256 sentinelOutAmount = sentinel.getQuote(1e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(1e18, base, quote);

        assertEq(sentinelOutAmount, maxPrice);
        assertEq(adapterOutAmount, price);

        sentinelOutAmount = sentinel.getQuote(1e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(1e18, quote, base);
        assertEq(sentinelOutAmount, 1e36 / maxPrice);
        assertEq(adapterOutAmount, 1e36 / price);
    }

    function test_Quote_IncreaseOverMaxGrowthOverCeil() public {
        vm.warp(40);
        uint256 price = 6e18;
        setPrice(price);
        assertEq(sentinel.maxRate(), CEIL_RATE);

        uint256 sentinelOutAmount = sentinel.getQuote(1e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(1e18, base, quote);

        assertEq(sentinelOutAmount, CEIL_RATE);
        assertEq(adapterOutAmount, price);

        sentinelOutAmount = sentinel.getQuote(1e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(1e18, quote, base);
        assertEq(sentinelOutAmount, 1e36 / CEIL_RATE);
        assertEq(adapterOutAmount, 1e36 / price);
    }

    function setPrice(uint256 price) internal {
        wrappedAdapter.setPrice(base, quote, price);
        wrappedAdapter.setPrice(quote, base, 1e36 / price);
    }
}
