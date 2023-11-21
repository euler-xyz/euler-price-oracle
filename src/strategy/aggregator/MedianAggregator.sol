// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {LibSort} from "@solady/utils/LibSort.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";

contract MedianAggregator is Aggregator {
    constructor(address[] memory _oracles, uint256 _quorum) Aggregator(_oracles, _quorum) {}

    function _aggregateQuotes(uint256[] memory quotes, PackedUint32Array) internal pure override returns (uint256) {
        // sort and return the median
        LibSort.insertionSort(quotes);
        uint256 length = quotes.length;
        uint256 midpoint = length / 2;
        if (length % 2 == 1) {
            return quotes[midpoint];
        } else {
            return (quotes[midpoint] + quotes[midpoint - 1]) / 2;
        }
    }
}
