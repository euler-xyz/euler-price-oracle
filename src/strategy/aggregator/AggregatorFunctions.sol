// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {LibSort} from "@solady/utils/LibSort.sol";

/// @author totomanov
/// @notice Statistical algorithms for oracle aggregators.
/// @dev All functions take an array of quotes.
/// Algorithms MUST NOT revert unless due to numerical over/underflow.
/// Algorithms MUST assume that `quotes` is non-empty and has no more than 8 elements.
/// Algorithms MAY define additional parameters such as weights.
library AggregatorFunctions {
    /// @dev Return the largest value from the list.
    function max(uint256[] memory quotes) internal pure returns (uint256) {
        uint256 _max;

        for (uint256 i = 0; i < quotes.length;) {
            if (quotes[i] > _max) _max = quotes[i];

            unchecked {
                ++i;
            }
        }

        return _max;
    }

    /// @dev Return the arithmetic mean of the quotes list.
    function mean(uint256[] memory quotes) internal pure returns (uint256) {
        uint256 sum;

        for (uint256 i = 0; i < quotes.length;) {
            sum += quotes[i];
            unchecked {
                ++i;
            }
        }

        return sum / quotes.length;
    }

    /// @dev Return the median value in the quotes list.
    /// Uses Solady's LibSort to sort the quotes.
    /// If the array has odd length, then return the average of the two middle values.
    function median(uint256[] memory quotes) internal pure returns (uint256) {
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

    /// @dev Return the smallest value from the list.
    function min(uint256[] memory quotes) internal pure returns (uint256) {
        uint256 _min = type(uint256).max;

        for (uint256 i = 0; i < quotes.length;) {
            if (quotes[i] < _min) _min = quotes[i];
            unchecked {
                ++i;
            }
        }

        return _min;
    }
}
