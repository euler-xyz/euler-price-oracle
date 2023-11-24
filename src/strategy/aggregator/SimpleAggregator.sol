// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {LibSort} from "@solady/utils/LibSort.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";

contract SimpleAggregator is Aggregator {
    enum Algorithm {
        MAX,
        MEAN,
        MEDIAN,
        MIN
    }

    function(uint256[] memory, PackedUint32Array) view returns (uint256) internal immutable algorithm;

    constructor(address[] memory _oracles, uint256 _quorum, Algorithm _algorithm) Aggregator(_oracles, _quorum) {
        if (_algorithm == Algorithm.MAX) {
            algorithm = _max;
        } else if (_algorithm == Algorithm.MEAN) {
            algorithm = _mean;
        } else if (_algorithm == Algorithm.MEDIAN) {
            algorithm = _median;
        } else if (_algorithm == Algorithm.MIN) {
            algorithm = _min;
        }
    }

    function description() external pure override returns (OracleDescription.Description memory) {
        return OracleDescription.SimpleAggregator();
    }

    function _aggregateQuotes(uint256[] memory quotes, PackedUint32Array mask)
        internal
        view
        override
        returns (uint256)
    {
        return algorithm(quotes, mask);
    }

    function _max(uint256[] memory quotes, PackedUint32Array) private pure returns (uint256) {
        uint256 max;

        for (uint256 i = 0; i < quotes.length;) {
            if (quotes[i] > max) max = quotes[i];

            unchecked {
                ++i;
            }
        }

        return max;
    }

    function _mean(uint256[] memory quotes, PackedUint32Array) private pure returns (uint256) {
        uint256 sum;

        for (uint256 i = 0; i < quotes.length;) {
            sum += quotes[i];
            unchecked {
                ++i;
            }
        }

        return sum / quotes.length;
    }

    function _median(uint256[] memory quotes, PackedUint32Array) private pure returns (uint256) {
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

    function _min(uint256[] memory quotes, PackedUint32Array) private pure returns (uint256) {
        uint256 min = type(uint256).max;

        for (uint256 i = 0; i < quotes.length;) {
            if (quotes[i] < min) min = quotes[i];
            unchecked {
                ++i;
            }
        }

        return min;
    }
}
