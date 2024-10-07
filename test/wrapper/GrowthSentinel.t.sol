// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {StubPriceOracle} from "test/adapter/StubPriceOracle.sol";
import {GrowthSentinel} from "src/wrapper/GrowthSentinel.sol";

contract GrowthSentinelTest is Test {
    address base = makeAddr("BASE");
    address quote = makeAddr("QUOTE");
    uint256 INITIAL_PRICE = 2e18;
    uint256 MAX_GROWTH = 0.1e18;
    StubPriceOracle wrappedAdapter;
    GrowthSentinel sentinel;

    function setUp() public {
        vm.warp(0);
        wrappedAdapter = new StubPriceOracle();
        vm.mockCall(base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(18));
        vm.mockCall(quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(18));
        setPrice(INITIAL_PRICE);
        sentinel = new GrowthSentinel(address(wrappedAdapter), base, quote, MAX_GROWTH);
    }

    function test_Quote_NoIncrease() public {
        vm.warp(10);
        setPrice(INITIAL_PRICE);

        uint256 sentinelOutAmount = sentinel.getQuote(1e18, base, quote);
        uint256 adapterOutAmount = wrappedAdapter.getQuote(1e18, base, quote);
        assertEq(sentinelOutAmount, INITIAL_PRICE);
        assertEq(adapterOutAmount, INITIAL_PRICE);

        sentinelOutAmount = sentinel.getQuote(1e18, quote, base);
        adapterOutAmount = wrappedAdapter.getQuote(1e18, quote, base);
        assertEq(sentinelOutAmount, 1e36 / INITIAL_PRICE);
        assertEq(adapterOutAmount, 1e36 / INITIAL_PRICE);
    }

    function test_Quote_IncreaseAtMaxGrowth() public {
        vm.warp(10);
        uint256 price = INITIAL_PRICE + MAX_GROWTH * 10;
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

    function test_Quote_IncreaseOverMaxGrowth() public {
        vm.warp(20);
        uint256 price = 5e18;
        setPrice(price);
        uint256 maxPrice = INITIAL_PRICE + MAX_GROWTH * 20;
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

    function setPrice(uint256 price) internal {
        wrappedAdapter.setPrice(base, quote, price);
        wrappedAdapter.setPrice(quote, base, 1e36 / price);
    }
}
