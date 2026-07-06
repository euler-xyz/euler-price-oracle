// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {stdError} from "forge-std/StdError.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {AggregatorV3Interface} from "src/adapter/chainlink/AggregatorV3Interface.sol";
import {ChainlinkInfrequentNanosecondOracle} from "src/adapter/chainlink/ChainlinkInfrequentNanosecondOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract ChainlinkInfrequentNanosecondOracleTest is AdapterHelper {
    address internal base;
    address internal quote;
    address internal feed;

    /// @dev Nanoseconds per second. The feed reports `updatedAt` in nanoseconds.
    uint256 internal constant NANO = 1e9;
    uint256 internal constant MAX_STALENESS = 24 hours;
    uint256 internal constant MAX_STALENESS_LOWER_BOUND = 1 minutes;

    function setUp() public {
        base = makeAddr("base");
        quote = makeAddr("quote");
        feed = makeAddr("feed");

        vm.mockCall(base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(uint8(18)));
        vm.mockCall(quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(uint8(18)));
        vm.mockCall(feed, abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(uint8(18)));
    }

    function _deployOracle() internal {
        oracle = address(new ChainlinkInfrequentNanosecondOracle(base, quote, feed, MAX_STALENESS));
    }

    /// @param answer The feed price (18 decimals).
    /// @param updatedAtNs The feed's last update time expressed in nanoseconds.
    function _mockFeed(int256 answer, uint256 updatedAtNs) internal {
        vm.mockCall(
            feed,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), answer, uint256(0), updatedAtNs, uint80(1))
        );
    }

    // -----------------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------------

    function test_Constructor_Integrity() public {
        _deployOracle();
        ChainlinkInfrequentNanosecondOracle o = ChainlinkInfrequentNanosecondOracle(oracle);
        assertEq(o.name(), "ChainlinkInfrequentNanosecondOracle");
        assertEq(o.base(), base);
        assertEq(o.quote(), quote);
        assertEq(o.feed(), feed);
        assertEq(o.maxStaleness(), MAX_STALENESS);
    }

    function test_Constructor_RevertsWhen_MaxStalenessTooLow() public {
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_InvalidConfiguration.selector));
        new ChainlinkInfrequentNanosecondOracle(base, quote, feed, MAX_STALENESS_LOWER_BOUND - 1);
    }

    // -----------------------------------------------------------------------
    // Quote integrity
    // -----------------------------------------------------------------------

    function test_Quote_Integrity() public {
        _deployOracle();
        uint256 ts = 2_000_000;
        _mockFeed(2e18, ts * NANO); // fresh: updated this very second
        vm.warp(ts);

        // 18/18/18 decimals, price 2e18 -> 1e18 base is worth 2e18 quote.
        assertEq(ChainlinkInfrequentNanosecondOracle(oracle).getQuote(1e18, base, quote), 2e18);

        (uint256 bid, uint256 ask) = ChainlinkInfrequentNanosecondOracle(oracle).getQuotes(1e18, base, quote);
        assertEq(bid, 2e18);
        assertEq(ask, 2e18);
    }

    function test_Quote_Integrity_Inverse() public {
        _deployOracle();
        uint256 ts = 2_000_000;
        _mockFeed(2e18, ts * NANO);
        vm.warp(ts);

        // Inverse direction: 1e18 quote is worth 0.5e18 base.
        assertEq(ChainlinkInfrequentNanosecondOracle(oracle).getQuote(1e18, quote, base), 0.5e18);
    }

    function test_Quote_RevertsWhen_InvalidTokens() public {
        _deployOracle();
        address other = makeAddr("other");
        expectNotSupported(1e18, base, base);
        expectNotSupported(1e18, quote, quote);
        expectNotSupported(1e18, base, other);
        expectNotSupported(1e18, other, quote);
    }

    function test_Quote_RevertsWhen_ZeroPrice() public {
        _deployOracle();
        uint256 ts = 2_000_000;
        _mockFeed(0, ts * NANO);
        vm.warp(ts);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector));
        ChainlinkInfrequentNanosecondOracle(oracle).getQuote(1e18, base, quote);
    }

    function test_Quote_RevertsWhen_NegativePrice() public {
        _deployOracle();
        uint256 ts = 2_000_000;
        _mockFeed(-1, ts * NANO);
        vm.warp(ts);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_InvalidAnswer.selector));
        ChainlinkInfrequentNanosecondOracle(oracle).getQuote(1e18, base, quote);
    }

    // -----------------------------------------------------------------------
    // Nanosecond staleness handling (the modified behavior)
    // -----------------------------------------------------------------------

    /// @dev `updatedAt` is denominated in nanoseconds and must be divided by 1e9 before
    /// being compared against `block.timestamp`. A feed updated 10s ago is fresh.
    function test_Staleness_ConvertsNanosecondsToSeconds() public {
        _deployOracle();
        uint256 ts = 2_000_000;
        uint256 ageSeconds = 10;
        _mockFeed(1e18, (ts - ageSeconds) * NANO);
        vm.warp(ts);

        // Would underflow/revert if `updatedAt` were (wrongly) treated as seconds.
        ChainlinkInfrequentNanosecondOracle(oracle).getQuote(1e18, base, quote);
    }

    /// @dev staleness == maxStaleness is exactly on the boundary and is NOT stale.
    function test_Staleness_BoundaryIsNotStale() public {
        _deployOracle();
        uint256 ts = 2_000_000;
        _mockFeed(1e18, (ts - MAX_STALENESS) * NANO);
        vm.warp(ts);

        ChainlinkInfrequentNanosecondOracle(oracle).getQuote(1e18, base, quote);
    }

    function test_Staleness_RevertsWhen_TooStale() public {
        _deployOracle();
        uint256 ts = 2_000_000;
        uint256 staleness = MAX_STALENESS + 1;
        _mockFeed(1e18, (ts - staleness) * NANO);
        vm.warp(ts);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, staleness, MAX_STALENESS));
        ChainlinkInfrequentNanosecondOracle(oracle).getQuote(1e18, base, quote);
    }

    /// @dev Sub-second nanosecond precision is truncated: an `updatedAt` up to 1e9-1 ns
    /// beyond the current second still floors to the current second (staleness 0).
    function test_Staleness_SubSecondPrecisionIsTruncated() public {
        _deployOracle();
        uint256 ts = 2_000_000;
        _mockFeed(1e18, ts * NANO + (NANO - 1)); // 0.999999999s "into the future"
        vm.warp(ts);

        ChainlinkInfrequentNanosecondOracle(oracle).getQuote(1e18, base, quote);
    }

    /// @dev A genuine future update (>= 1 full second ahead) underflows and reverts (panic 0x11).
    function test_Staleness_RevertsWhen_UpdatedInFuture() public {
        _deployOracle();
        uint256 ts = 2_000_000;
        _mockFeed(1e18, (ts + 1) * NANO); // one full second in the future
        vm.warp(ts);

        vm.expectRevert(stdError.arithmeticError);
        ChainlinkInfrequentNanosecondOracle(oracle).getQuote(1e18, base, quote);
    }

    // -----------------------------------------------------------------------
    // Fuzz
    // -----------------------------------------------------------------------

    function test_Fuzz_Staleness_FreshWhenWithinMaxStaleness(uint256 ts, uint256 age) public {
        _deployOracle();
        ts = bound(ts, MAX_STALENESS, type(uint64).max);
        age = bound(age, 0, MAX_STALENESS);
        _mockFeed(1e18, (ts - age) * NANO);
        vm.warp(ts);

        assertEq(ChainlinkInfrequentNanosecondOracle(oracle).getQuote(1e18, base, quote), 1e18);
    }

    function test_Fuzz_Staleness_RevertsWhenBeyondMaxStaleness(uint256 ts, uint256 age) public {
        _deployOracle();
        ts = bound(ts, MAX_STALENESS + 2, type(uint64).max);
        age = bound(age, MAX_STALENESS + 1, ts);
        _mockFeed(1e18, (ts - age) * NANO);
        vm.warp(ts);

        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_TooStale.selector, age, MAX_STALENESS));
        ChainlinkInfrequentNanosecondOracle(oracle).getQuote(1e18, base, quote);
    }
}
