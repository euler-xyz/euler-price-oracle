// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {AggregatorAlgorithms} from "src/strategy/aggregator/AggregatorAlgorithms.sol";

contract AggregatorAlgorithmsHarness {
    function max(uint256[] memory quotes, PackedUint32Array mask) external pure returns (uint256) {
        return AggregatorAlgorithms.max(quotes, mask);
    }

    function mean(uint256[] memory quotes, PackedUint32Array mask) external pure returns (uint256) {
        return AggregatorAlgorithms.mean(quotes, mask);
    }

    function median(uint256[] memory quotes, PackedUint32Array mask) external pure returns (uint256) {
        return AggregatorAlgorithms.median(quotes, mask);
    }

    function min(uint256[] memory quotes, PackedUint32Array mask) external pure returns (uint256) {
        return AggregatorAlgorithms.min(quotes, mask);
    }

    function weightedMean(uint256[] memory quotes, PackedUint32Array weights, PackedUint32Array mask)
        internal
        pure
        returns (uint256)
    {
        return AggregatorAlgorithms.weightedMean(quotes, weights, mask);
    }
}
