// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {AggregatorV3Interface} from "@chainlink/interfaces/AggregatorV3Interface.sol";
import {FeedRegistryInterface} from "@chainlink/interfaces/FeedRegistryInterface.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {IFactoryInitializable} from "src/interfaces/IFactoryInitializable.sol";
import {Errors} from "src/lib/Errors.sol";

contract ChainlinkOracleTest is Test {
    address internal GOVERNOR = makeAddr("GOVERNOR");
    address internal FEED_REGISTRY = makeAddr("FEED_REGISTRY");
    address internal WETH = makeAddr("WETH");

    ChainlinkOracle oracle;

    struct FuzzableConfig {
        ChainlinkOracle.ConfigParams params;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        uint8 feedDecimals;
    }

    function setUp() public {
        oracle = new ChainlinkOracle(FEED_REGISTRY, WETH, new ChainlinkOracle.ConfigParams[](0));
        oracle.initialize(GOVERNOR);
    }

    function test_GovSetConfig_OnlyCallableByGovernor(address caller, ChainlinkOracle.ConfigParams memory params)
        public
    {
        vm.assume(caller != GOVERNOR);
        vm.prank(caller);
        vm.expectRevert(IFactoryInitializable.CallerNotGovernor.selector);
        oracle.govSetConfig(params);
    }

    function test_GovSetConfig_CallableByGovernor(FuzzableConfig memory c) public {
        _prepareValidConfig(c);
        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);
    }

    function test_GovSetConfig_Integrity(FuzzableConfig memory c) public {
        _prepareValidConfig(c);
        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        {
            (
                address feed,
                uint32 maxStaleness,
                uint32 maxDuration,
                uint8 baseDecimals,
                uint8 quoteDecimals,
                uint8 feedDecimals,
                bool inverse
            ) = oracle.configs(c.params.base, c.params.quote);

            assertEq(feed, c.params.feed);
            assertEq(maxStaleness, c.params.maxStaleness);
            assertEq(maxDuration, c.params.maxDuration);
            assertEq(baseDecimals, c.baseDecimals);
            assertEq(quoteDecimals, c.quoteDecimals);
            assertEq(feedDecimals, c.feedDecimals);
            assertEq(inverse, c.params.inverse);
        }

        {
            (
                address feed,
                uint32 maxStaleness,
                uint32 maxDuration,
                uint8 baseDecimals,
                uint8 quoteDecimals,
                uint8 feedDecimals,
                bool inverse
            ) = oracle.configs(c.params.quote, c.params.base);

            assertEq(feed, c.params.feed);
            assertEq(maxStaleness, c.params.maxStaleness);
            assertEq(maxDuration, c.params.maxDuration);
            assertEq(baseDecimals, c.quoteDecimals);
            assertEq(quoteDecimals, c.baseDecimals);
            assertEq(feedDecimals, c.feedDecimals);
            assertEq(inverse, !c.params.inverse);
        }
    }

    function test_GovUnsetConfig_Integrity(FuzzableConfig memory c) public {
        _prepareValidConfig(c);

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.prank(GOVERNOR);
        oracle.govUnsetConfig(c.params.base, c.params.quote);

        {
            (
                address feed,
                uint32 maxStaleness,
                uint32 maxDuration,
                uint8 baseDecimals,
                uint8 quoteDecimals,
                uint8 feedDecimals,
                bool inverse
            ) = oracle.configs(c.params.base, c.params.quote);

            assertEq(feed, address(0));
            assertEq(maxStaleness, 0);
            assertEq(maxDuration, 0);
            assertEq(baseDecimals, 0);
            assertEq(quoteDecimals, 0);
            assertEq(feedDecimals, 0);
            assertEq(inverse, false);
        }

        {
            (
                address feed,
                uint32 maxStaleness,
                uint32 maxDuration,
                uint8 baseDecimals,
                uint8 quoteDecimals,
                uint8 feedDecimals,
                bool inverse
            ) = oracle.configs(c.params.quote, c.params.base);

            assertEq(feed, address(0));
            assertEq(maxStaleness, 0);
            assertEq(maxDuration, 0);
            assertEq(baseDecimals, 0);
            assertEq(quoteDecimals, 0);
            assertEq(feedDecimals, 0);
            assertEq(inverse, false);
        }
    }

    function test_GovUnsetConfig_Integrity_Reverse(FuzzableConfig memory c) public {
        _prepareValidConfig(c);

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.prank(GOVERNOR);
        oracle.govUnsetConfig(c.params.quote, c.params.base);

        {
            (
                address feed,
                uint32 maxStaleness,
                uint32 maxDuration,
                uint8 baseDecimals,
                uint8 quoteDecimals,
                uint8 feedDecimals,
                bool inverse
            ) = oracle.configs(c.params.base, c.params.quote);

            assertEq(feed, address(0));
            assertEq(maxStaleness, 0);
            assertEq(maxDuration, 0);
            assertEq(baseDecimals, 0);
            assertEq(quoteDecimals, 0);
            assertEq(feedDecimals, 0);
            assertEq(inverse, false);
        }

        {
            (
                address feed,
                uint32 maxStaleness,
                uint32 maxDuration,
                uint8 baseDecimals,
                uint8 quoteDecimals,
                uint8 feedDecimals,
                bool inverse
            ) = oracle.configs(c.params.quote, c.params.base);

            assertEq(feed, address(0));
            assertEq(maxStaleness, 0);
            assertEq(maxDuration, 0);
            assertEq(baseDecimals, 0);
            assertEq(quoteDecimals, 0);
            assertEq(feedDecimals, 0);
            assertEq(inverse, false);
        }
    }

    function test_GetQuote_RevertsWhen_NoConfig(FuzzableConfig memory c, uint256 inAmount) public {
        _prepareValidConfig(c);

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, c.params.base, c.params.quote));
        oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    function test_GetQuote_RevertsWhen_FeedRegistryReverts(FuzzableConfig memory c, uint256 inAmount) public {
        _prepareValidConfig(c);

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));
        c.params.feed = FEED_REGISTRY;
        vm.mockCall(FEED_REGISTRY, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.feedDecimals));

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.mockCallRevert(FEED_REGISTRY, abi.encodeWithSelector(FeedRegistryInterface.latestRoundData.selector), "oops");
        vm.expectRevert(abi.encodeWithSelector(Errors.Chainlink_CallReverted.selector, "oops"));
        oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    function test_GetQuote_RevertsWhen_AggregatorV3Reverts(FuzzableConfig memory c, uint256 inAmount) public {
        _prepareValidConfig(c);
        vm.assume(c.params.feed != FEED_REGISTRY);

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.mockCallRevert(c.params.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), "oops");
        vm.expectRevert(abi.encodeWithSelector(Errors.Chainlink_CallReverted.selector, "oops"));
        oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    function test_GetQuote_RevertsWhen_ZeroPrice(FuzzableConfig memory c, FuzzableRoundData memory d, uint256 inAmount)
        public
    {
        _prepareValidConfig(c);
        vm.assume(c.params.feed != FEED_REGISTRY);

        _prepareValidRoundData(d);
        d.answer = 0;

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.mockCall(
            c.params.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(d)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Chainlink_InvalidAnswer.selector, 0));
        oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    function test_GetQuote_RevertsWhen_NegativePrice(
        FuzzableConfig memory c,
        FuzzableRoundData memory d,
        uint256 inAmount,
        int256 chainlinkAnswer
    ) public {
        _prepareValidConfig(c);
        vm.assume(c.params.feed != FEED_REGISTRY);

        _prepareValidRoundData(d);
        chainlinkAnswer = bound(chainlinkAnswer, type(int256).min, -1);
        d.answer = chainlinkAnswer;

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.mockCall(
            c.params.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(d)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Chainlink_InvalidAnswer.selector, chainlinkAnswer));
        oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    function test_GetQuote_RevertsWhen_RoundIncomplete(
        FuzzableConfig memory c,
        FuzzableRoundData memory d,
        uint256 inAmount
    ) public {
        _prepareValidConfig(c);
        vm.assume(c.params.feed != FEED_REGISTRY);

        _prepareValidRoundData(d);
        d.updatedAt = 0;

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.mockCall(
            c.params.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(d)
        );
        vm.expectRevert(abi.encodeWithSelector(Errors.Chainlink_RoundIncomplete.selector));
        oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    function test_GetQuote_Integrity_CallFeedRegistry(FuzzableConfig memory c, uint256 inAmount) public {
        _prepareValidConfig(c);
        inAmount = bound(inAmount, 1, uint256(type(uint128).max));
        c.params.feed = FEED_REGISTRY;
        vm.mockCall(FEED_REGISTRY, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.feedDecimals));

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.warp(8);
        vm.mockCall(
            FEED_REGISTRY,
            abi.encodeWithSelector(FeedRegistryInterface.latestRoundData.selector, c.params.base, c.params.quote),
            abi.encode(uint80(0), int256(1), uint256(8), uint256(8), uint80(0))
        );
        uint256 res = oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    function _prepareValidConfig(FuzzableConfig memory c) private {
        c.params.base = boundAddr(c.params.base);
        c.params.quote = boundAddr(c.params.quote);
        c.params.feed = boundAddr(c.params.feed);
        vm.assume(c.params.base != c.params.quote && c.params.quote != c.params.feed && c.params.base != c.params.feed);
        vm.assume(c.params.base != WETH && c.params.quote != WETH && c.params.feed != WETH);

        c.baseDecimals = uint8(bound(c.baseDecimals, 0, 24));
        c.quoteDecimals = uint8(bound(c.quoteDecimals, 0, 24));
        c.feedDecimals = uint8(bound(c.feedDecimals, 0, 24));

        vm.mockCall(c.params.base, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.baseDecimals));
        vm.mockCall(c.params.quote, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.quoteDecimals));
        vm.mockCall(c.params.feed, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.feedDecimals));
    }

    struct FuzzableRoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    function _prepareValidRoundData(FuzzableRoundData memory d) private {
        d.answer = bound(d.answer, 1, int256(type(int128).max));
    }
}
