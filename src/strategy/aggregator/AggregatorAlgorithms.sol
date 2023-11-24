// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {LibSort} from "@solady/utils/LibSort.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";

library AggregatorAlgorithms {
    function max(uint256[] memory quotes, PackedUint32Array) internal pure returns (uint256) {
        uint256 _max;

        for (uint256 i = 0; i < quotes.length;) {
            if (quotes[i] > _max) _max = quotes[i];

            unchecked {
                ++i;
            }
        }

        return _max;
    }

    function mean(uint256[] memory quotes, PackedUint32Array) internal pure returns (uint256) {
        uint256 sum;

        for (uint256 i = 0; i < quotes.length;) {
            sum += quotes[i];
            unchecked {
                ++i;
            }
        }

        return sum / quotes.length;
    }

    function median(uint256[] memory quotes, PackedUint32Array) internal pure returns (uint256) {
        // sort and return the median
        LibSort.insertionSort(quotes);
        uint256 length = quotes.length;
        uint256 midpoint = length / 2;
        if (length % 2 == 1) {
            return quotes[midpoint];
        } else {
            return FixedPointMathLib.avg(quotes[midpoint], quotes[midpoint - 1]);
        }
    }

    function min(uint256[] memory quotes, PackedUint32Array) internal pure returns (uint256) {
        uint256 _min = type(uint256).max;

        for (uint256 i = 0; i < quotes.length;) {
            if (quotes[i] < _min) _min = quotes[i];
            unchecked {
                ++i;
            }
        }

        return _min;
    }

    function weightedArithmeticMean(uint256[] memory quotes, PackedUint32Array weights, PackedUint32Array successMask)
        internal
        pure
        returns (uint256)
    {
        uint256 totalWeight = weights.mask(successMask).sum();
        uint256 weightedSum;
        uint256 length = quotes.length;

        uint256 j;
        for (uint256 i = 0; i < length;) {
            for (; j < length;) {
                if (successMask.get(j) != 0) break;
                unchecked {
                    ++j;
                }
            }
            weightedSum += quotes[i] * weights.get(j);
            unchecked {
                ++i;
            }
        }

        return weightedSum / totalWeight;
    }
}
