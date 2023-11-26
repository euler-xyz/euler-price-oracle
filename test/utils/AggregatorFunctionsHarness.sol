// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {AggregatorFunctions} from "src/strategy/aggregator/AggregatorFunctions.sol";

contract AggregatorFunctionsHarness {
    function max(uint256[] memory quotes, PackedUint32Array mask) external pure returns (uint256) {
        return AggregatorFunctions.max(quotes, mask);
    }

    function mean(uint256[] memory quotes, PackedUint32Array mask) external pure returns (uint256) {
        return AggregatorFunctions.mean(quotes, mask);
    }

    function median(uint256[] memory quotes, PackedUint32Array mask) external pure returns (uint256) {
        return AggregatorFunctions.median(quotes, mask);
    }

    function min(uint256[] memory quotes, PackedUint32Array mask) external pure returns (uint256) {
        return AggregatorFunctions.min(quotes, mask);
    }

    function weightedMean(uint256[] memory quotes, PackedUint32Array weights, PackedUint32Array mask)
        internal
        pure
        returns (uint256)
    {
        return AggregatorFunctions.weightedMean(quotes, weights, mask);
    }
}
