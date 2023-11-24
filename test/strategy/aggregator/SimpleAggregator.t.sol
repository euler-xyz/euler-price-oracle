// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {LibPRNG} from "@solady/utils/LibPRNG.sol";
import {SimpleAggregatorHarness} from "test/utils/SimpleAggregatorHarness.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {SimpleAggregator} from "src/strategy/aggregator/SimpleAggregator.sol";

contract SimpleAggregatorTest is Test {
    uint256 private constant SHUFFLE_ITERATIONS = 10;
    SimpleAggregatorHarness internal immutable maxHarness;
    SimpleAggregatorHarness internal immutable meanHarness;
    SimpleAggregatorHarness internal immutable medianHarness;
    SimpleAggregatorHarness internal immutable minHarness;

    constructor() {
        address[] memory oracles = new address[](1);
        oracles[0] = makeAddr("oracle");
        maxHarness = new SimpleAggregatorHarness(oracles, 1, SimpleAggregator.Algorithm.MAX);
        meanHarness = new SimpleAggregatorHarness(oracles, 1, SimpleAggregator.Algorithm.MEAN);
        medianHarness = new SimpleAggregatorHarness(oracles, 1, SimpleAggregator.Algorithm.MEDIAN);
        minHarness = new SimpleAggregatorHarness(oracles, 1, SimpleAggregator.Algorithm.MIN);
    }

    function test_Max_Concrete(LibPRNG.PRNG memory prng, PackedUint32Array mask) public {
        uint256[] memory quotes = new uint256[](3);
        quotes[0] = 0;
        quotes[1] = 1;
        quotes[2] = 2;

        for (uint256 i = 0; i < SHUFFLE_ITERATIONS; ++i) {
            LibPRNG.shuffle(prng, quotes);
            uint256 result = maxHarness.aggregateQuotes(quotes, mask);
            assertEq(result, 2);
        }
    }

    function test_Mean_Concrete(LibPRNG.PRNG memory prng, PackedUint32Array mask) public {
        uint256[] memory quotes = new uint256[](3);
        quotes[0] = 0;
        quotes[1] = 1;
        quotes[2] = 2;

        for (uint256 i = 0; i < SHUFFLE_ITERATIONS; ++i) {
            LibPRNG.shuffle(prng, quotes);
            uint256 result = meanHarness.aggregateQuotes(quotes, mask);
            assertEq(result, 1);
        }
    }

    function test_Median_Concrete(LibPRNG.PRNG memory prng, PackedUint32Array mask) public {
        uint256[] memory quotes = new uint256[](3);
        quotes[0] = 0;
        quotes[1] = 1;
        quotes[2] = 2;

        for (uint256 i = 0; i < SHUFFLE_ITERATIONS; ++i) {
            LibPRNG.shuffle(prng, quotes);
            uint256 result = medianHarness.aggregateQuotes(quotes, mask);
            assertEq(result, 1);
        }
    }

    function test_Min_Concrete(LibPRNG.PRNG memory prng, PackedUint32Array mask) public {
        uint256[] memory quotes = new uint256[](3);
        quotes[0] = 0;
        quotes[1] = 1;
        quotes[2] = 2;

        for (uint256 i = 0; i < SHUFFLE_ITERATIONS; ++i) {
            LibPRNG.shuffle(prng, quotes);
            uint256 result = minHarness.aggregateQuotes(quotes, mask);
            assertEq(result, 0);
        }
    }

    function test_StatisticalIntegrity(uint256[] memory quotes, PackedUint32Array mask) public {
        vm.assume(quotes.length != 0);
        _noSumOverflow(quotes);

        uint256 min = minHarness.aggregateQuotes(quotes, mask);
        uint256 mean = meanHarness.aggregateQuotes(quotes, mask);
        uint256 median = medianHarness.aggregateQuotes(quotes, mask);
        uint256 max = maxHarness.aggregateQuotes(quotes, mask);
        assertLe(min, max, "min <= max");
        assertLe(min, mean, "min <= mean");
        assertLe(min, median, "min <= median");
        assertLe(mean, max, "mean <= max");
        assertLe(median, max, "median <= max");
    }

    function test_StableUnderPermutation(uint256[] memory quotes, LibPRNG.PRNG memory prng, PackedUint32Array mask)
        public
    {
        vm.assume(quotes.length != 0);
        _noSumOverflow(quotes);

        uint256 min = minHarness.aggregateQuotes(quotes, mask);
        uint256 mean = meanHarness.aggregateQuotes(quotes, mask);
        uint256 median = medianHarness.aggregateQuotes(quotes, mask);
        uint256 max = maxHarness.aggregateQuotes(quotes, mask);

        for (uint256 i = 0; i < SHUFFLE_ITERATIONS; ++i) {
            LibPRNG.shuffle(prng, quotes);
            uint256 _min = minHarness.aggregateQuotes(quotes, mask);
            uint256 _mean = meanHarness.aggregateQuotes(quotes, mask);
            uint256 _median = medianHarness.aggregateQuotes(quotes, mask);
            uint256 _max = maxHarness.aggregateQuotes(quotes, mask);

            assertLe(min, _min);
            assertLe(mean, _mean);
            assertLe(median, _median);
            assertLe(max, _max);
        }
    }

    function _noSumOverflow(uint256[] memory arr) private view {
        for (uint256 i = 0; i < arr.length; ++i) {
            arr[i] = bound(arr[i], 0, 2 ** 248);
        }
    }
}
