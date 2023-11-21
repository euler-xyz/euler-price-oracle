// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Test} from "forge-std/Test.sol";
import {LibPRNG} from "@solady/utils/LibPRNG.sol";
import {MedianAggregatorHarness} from "test/utils/MedianAggregatorHarness.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";

contract MedianAggregatorTest is Test {
    uint256 private constant SHUFFLE_ITERATIONS = 100;
    MedianAggregatorHarness immutable harness;

    constructor() {
        address[] memory oracles = new address[](1);
        oracles[0] = makeAddr("oracle");
        harness = new MedianAggregatorHarness(oracles, 1);
    }

    function test_AggregateQuotes_OddSize_Concrete(LibPRNG.PRNG memory prng, PackedUint32Array mask) public {
        uint256[] memory quotes = new uint256[](3);
        quotes[0] = 0;
        quotes[1] = 1;
        quotes[2] = 2;

        for (uint256 i = 0; i < SHUFFLE_ITERATIONS; ++i) {
            LibPRNG.shuffle(prng, quotes);
            uint256 result = harness.aggregateQuotes(quotes, mask);
            assertEq(result, 1);
        }
    }

    function test_AggregateQuotes_EvenSize_Concrete(LibPRNG.PRNG memory prng, PackedUint32Array mask) public {
        uint256[] memory quotes = new uint256[](4);
        quotes[0] = 0;
        quotes[1] = 1;
        quotes[2] = 3;
        quotes[3] = 4;

        for (uint256 i = 0; i < SHUFFLE_ITERATIONS; ++i) {
            LibPRNG.shuffle(prng, quotes);
            uint256 result = harness.aggregateQuotes(quotes, mask);
            assertEq(result, 2);
        }
    }
}
