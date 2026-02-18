// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {AggregatorV3Interface} from "src/adapter/chainlink/AggregatorV3Interface.sol";
import {
    ChainlinkInfrequentOracleXStocks,
    IBackedAutoFeeToken
} from "src/adapter/chainlink/ChainlinkInfrequentOraclXStocks.sol";
import {Errors} from "src/lib/Errors.sol";

contract ChainlinkInfrequentOraclXStocksTest is AdapterHelper {
    address internal base;
    address internal quote;
    address internal feed;
    address internal xStocksToken;

    uint256 internal constant PAUSE_TIME_BEFORE = 1 hours;
    uint256 internal constant PAUSE_TIME_AFTER = 1 hours;
    uint256 internal constant MAX_ALLOWED_MULTIPLIER_DIFF = 0.01e18;
    uint256 internal constant MAX_STALENESS = 24 hours;

    function setUp() public {
        base = makeAddr("base");
        quote = makeAddr("quote");
        feed = makeAddr("feed");
        xStocksToken = base;

        vm.mockCall(base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(uint8(18)));
        vm.mockCall(quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(uint8(18)));
        vm.mockCall(feed, abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(uint8(18)));
    }

    function _deployOracle() internal {
        _deployOracle(PAUSE_TIME_BEFORE, PAUSE_TIME_AFTER, MAX_ALLOWED_MULTIPLIER_DIFF);
    }

    function _deployOracle(uint256 pauseBefore, uint256 pauseAfter, uint256 minChange) internal {
        oracle = address(
            new ChainlinkInfrequentOracleXStocks(
                pauseBefore, pauseAfter, minChange, xStocksToken, base, quote, feed, MAX_STALENESS
            )
        );
    }

    function _mockFeed(uint256 updatedAt) internal {
        vm.mockCall(
            feed,
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(uint80(1), int256(1e18), uint256(0), updatedAt, uint80(1))
        );
    }

    function _mockMultiplierUpdatesLength(uint256 length) internal {
        vm.mockCall(
            xStocksToken,
            abi.encodeWithSelector(IBackedAutoFeeToken.multiplierUpdatesLength.selector),
            abi.encode(length)
        );
    }

    function _mockMultiplierUpdate(uint256 index, uint256 prevMult, uint256 newMult, uint256 activationTime) internal {
        vm.mockCall(
            xStocksToken,
            abi.encodeWithSelector(IBackedAutoFeeToken.multiplierUpdates.selector, index),
            abi.encode(prevMult, newMult, activationTime)
        );
    }

    // -----------------------------------------------------------------------
    // Constructor
    // -----------------------------------------------------------------------

    function test_Constructor_Integrity() public {
        _deployOracle();
        ChainlinkInfrequentOracleXStocks o = ChainlinkInfrequentOracleXStocks(oracle);
        assertEq(o.pauseTimeBefore(), PAUSE_TIME_BEFORE);
        assertEq(o.pauseTimeAfter(), PAUSE_TIME_AFTER);
        assertEq(o.maxAllowedMultiplierDiff(), MAX_ALLOWED_MULTIPLIER_DIFF);
        assertEq(o.xStocksToken(), xStocksToken);
    }

    function test_Constructor_RevertsWhen_XStocksTokenInvalid() public {
        address badToken = makeAddr("badToken");
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_InvalidConfiguration.selector));
        new ChainlinkInfrequentOracleXStocks(
            PAUSE_TIME_BEFORE, PAUSE_TIME_AFTER, MAX_ALLOWED_MULTIPLIER_DIFF, badToken, base, quote, feed, MAX_STALENESS
        );
    }

    function test_Constructor_XStocksTokenCanBeQuote() public {
        xStocksToken = quote;
        _deployOracle();
        assertEq(ChainlinkInfrequentOracleXStocks(oracle).xStocksToken(), quote);
    }

    // -----------------------------------------------------------------------
    // No pause scenarios
    // -----------------------------------------------------------------------

    function test_NoPause_WhenNoMultiplierUpdates() public {
        _deployOracle();
        uint256 ts = 1_000_000;
        _mockMultiplierUpdatesLength(0);
        _mockFeed(ts);
        vm.warp(ts);

        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_NoPause_WhenFutureUpdateOutsideBeforeBracket() public {
        _deployOracle();
        uint256 ts = 1_000_000;
        uint256 activationTime = ts + PAUSE_TIME_BEFORE + 1;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_NoPause_WhenPastUpdateOutsideAfterBracket() public {
        _deployOracle();
        uint256 activationTime = 1_000_000;
        uint256 ts = activationTime + PAUSE_TIME_AFTER + 1;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_NoPause_WhenChangeBelowThreshold() public {
        _deployOracle();
        uint256 ts = 1_000_000;
        uint256 activationTime = ts + PAUSE_TIME_BEFORE / 2;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1e18 + MAX_ALLOWED_MULTIPLIER_DIFF - 1, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_NoPause_WhenAllUpdatesOutsideBrackets() public {
        _deployOracle();
        uint256 ts = 1_000_000;
        uint256 activationTime0 = ts - PAUSE_TIME_AFTER - 100;
        uint256 activationTime1 = ts + PAUSE_TIME_BEFORE + 100;

        _mockMultiplierUpdatesLength(2);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime0);
        _mockMultiplierUpdate(1, 1.05e18, 1.10e18, activationTime1);
        _mockFeed(ts);
        vm.warp(ts);

        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    // -----------------------------------------------------------------------
    // Pause (revert) scenarios
    // -----------------------------------------------------------------------

    function test_Pause_FutureUpdateInBeforeBracket() public {
        _deployOracle();
        uint256 ts = 1_000_000;
        uint256 activationTime = ts + PAUSE_TIME_BEFORE / 2;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_Pause_FutureUpdateExactlyAtBeforeBracketBoundary() public {
        _deployOracle();
        uint256 ts = 1_000_000;
        uint256 activationTime = ts + PAUSE_TIME_BEFORE;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_Pause_PastUpdateInAfterBracket() public {
        _deployOracle();
        uint256 activationTime = 1_000_000;
        uint256 ts = activationTime + PAUSE_TIME_AFTER / 2;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_Pause_PastUpdateExactlyAtAfterBracketBoundary() public {
        _deployOracle();
        uint256 activationTime = 1_000_000;
        uint256 ts = activationTime + PAUSE_TIME_AFTER;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_Pause_UpdateExactlyAtActivationTime() public {
        _deployOracle();
        uint256 ts = 1_000_000;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, ts);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_Pause_ExactlyAtMinChange() public {
        _deployOracle();
        uint256 ts = 1_000_000;
        uint256 activationTime = ts + PAUSE_TIME_BEFORE / 2;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1e18 + MAX_ALLOWED_MULTIPLIER_DIFF, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_Pause_MultiplierDecrease() public {
        _deployOracle();
        uint256 ts = 1_000_000;
        uint256 activationTime = ts + PAUSE_TIME_BEFORE / 2;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1.05e18, 1e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    // -----------------------------------------------------------------------
    // Multi-update walk scenarios
    // -----------------------------------------------------------------------

    function test_Pause_WalksFutureUpdatesToFindPastInBracket() public {
        _deployOracle();
        uint256 ts = 1_000_000;

        // index 0: past, within after-bracket
        uint256 act0 = ts - PAUSE_TIME_AFTER / 2;
        // index 1: future, outside before-bracket
        uint256 act1 = ts + PAUSE_TIME_BEFORE + 100;
        // index 2: future, outside before-bracket
        uint256 act2 = ts + PAUSE_TIME_BEFORE + 200;

        _mockMultiplierUpdatesLength(3);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, act0);
        _mockMultiplierUpdate(1, 1.05e18, 1.10e18, act1);
        _mockMultiplierUpdate(2, 1.10e18, 1.15e18, act2);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_Pause_FutureUpdateInBracketAmongMultiple() public {
        _deployOracle();
        uint256 ts = 1_000_000;

        // index 0: past, outside after-bracket
        uint256 act0 = ts - PAUSE_TIME_AFTER - 100;
        // index 1: future, within before-bracket
        uint256 act1 = ts + PAUSE_TIME_BEFORE / 2;

        _mockMultiplierUpdatesLength(2);
        _mockMultiplierUpdate(0, 1e18, 1.001e18, act0);
        _mockMultiplierUpdate(1, 1.001e18, 1.05e18, act1);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_NoPause_WalksFutureUpdatesToFindPastOutsideBracket() public {
        _deployOracle();
        uint256 ts = 1_000_000;

        // index 0: past, outside after-bracket
        uint256 act0 = ts - PAUSE_TIME_AFTER - 100;
        // index 1: future, outside before-bracket
        uint256 act1 = ts + PAUSE_TIME_BEFORE + 100;

        _mockMultiplierUpdatesLength(2);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, act0);
        _mockMultiplierUpdate(1, 1.05e18, 1.10e18, act1);
        _mockFeed(ts);
        vm.warp(ts);

        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_NoPause_MultipleFutureSmallChangesInBracket() public {
        _deployOracle();
        uint256 ts = 1_000_000;

        // index 0: past, outside after-bracket, small change
        uint256 act0 = ts - PAUSE_TIME_AFTER - 100;
        // index 1: future, within before-bracket, small change (below threshold)
        uint256 act1 = ts + PAUSE_TIME_BEFORE / 2;

        _mockMultiplierUpdatesLength(2);
        _mockMultiplierUpdate(0, 1e18, 1e18 + MAX_ALLOWED_MULTIPLIER_DIFF - 1, act0);
        _mockMultiplierUpdate(1, 1e18, 1e18 + MAX_ALLOWED_MULTIPLIER_DIFF - 1, act1);
        _mockFeed(ts);
        vm.warp(ts);

        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    // -----------------------------------------------------------------------
    // getQuotes and inverse direction also pause
    // -----------------------------------------------------------------------

    function test_Pause_RevertsOnGetQuotes() public {
        _deployOracle();
        uint256 ts = 1_000_000;
        uint256 activationTime = ts + PAUSE_TIME_BEFORE / 2;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuotes(1e18, base, quote);
    }

    function test_Pause_RevertsOnInverseDirection() public {
        _deployOracle();
        uint256 ts = 1_000_000;
        uint256 activationTime = ts + PAUSE_TIME_BEFORE / 2;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, quote, base);
    }

    // -----------------------------------------------------------------------
    // Fuzz tests
    // -----------------------------------------------------------------------

    function test_Fuzz_PauseInBeforeBracket(uint256 ts, uint256 offset) public {
        _deployOracle();
        ts = bound(ts, 1, type(uint128).max);
        offset = bound(offset, 1, PAUSE_TIME_BEFORE);
        uint256 activationTime = ts + offset;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_Fuzz_PauseInAfterBracket(uint256 ts, uint256 offset) public {
        _deployOracle();
        offset = bound(offset, 0, PAUSE_TIME_AFTER);
        ts = bound(ts, offset + 1, type(uint128).max);
        uint256 activationTime = ts - offset;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        vm.expectRevert(
            abi.encodeWithSelector(ChainlinkInfrequentOracleXStocks.PriceOracle_MultiplierUpdatePause.selector)
        );
        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_Fuzz_NoPauseOutsideAfterBracket(uint256 ts, uint256 extra) public {
        _deployOracle();
        ts = bound(ts, PAUSE_TIME_AFTER + 2, type(uint64).max);
        extra = bound(extra, 1, ts - PAUSE_TIME_AFTER - 1);
        uint256 activationTime = ts - PAUSE_TIME_AFTER - extra;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_Fuzz_NoPauseOutsideBeforeBracket(uint256 ts, uint256 extra) public {
        _deployOracle();
        ts = bound(ts, 1, type(uint64).max);
        extra = bound(extra, 1, type(uint64).max);
        uint256 activationTime = ts + PAUSE_TIME_BEFORE + extra;

        // Need a past update outside after-bracket so the loop terminates cleanly
        // when no past updates exist (length=1 and it's future → loop ends at index 0).
        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1.05e18, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }

    function test_Fuzz_NoPauseChangeBelowThreshold(uint256 ts, uint256 change) public {
        _deployOracle();
        ts = bound(ts, 1, type(uint128).max);
        change = bound(change, 0, MAX_ALLOWED_MULTIPLIER_DIFF - 1);
        uint256 activationTime = ts + PAUSE_TIME_BEFORE / 2;

        _mockMultiplierUpdatesLength(1);
        _mockMultiplierUpdate(0, 1e18, 1e18 + change, activationTime);
        _mockFeed(ts);
        vm.warp(ts);

        ChainlinkInfrequentOracleXStocks(oracle).getQuote(1e18, base, quote);
    }
}
