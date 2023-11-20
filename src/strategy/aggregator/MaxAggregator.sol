// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {LibSort} from "@solady/utils/LibSort.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";

contract MaxAggregator is Aggregator {
    constructor(address[] memory _oracles, uint256 _quorum) Aggregator(_oracles, _quorum) {}

    function _aggregateQuotes(uint256[] memory quotes, PackedUint32Array) internal pure override returns (uint256) {
        // sort and return the highest quote
        LibSort.insertionSort(quotes);
        return quotes[quotes.length - 1];
    }
}
