// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {OracleDescription} from "src/lib/OracleDescription.sol";
import {PackedUint32Array, PackedUint32ArrayLib} from "src/lib/PackedUint32Array.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";

contract WeightedAggregator is Aggregator {
    PackedUint32Array public immutable weights;

    error ArityMismatch(uint256 arityA, uint256 arityB);

    constructor(address[] memory _oracles, uint256[] memory _weights, uint256 _quorum) Aggregator(_oracles, _quorum) {
        if (_oracles.length != _weights.length) revert ArityMismatch(_oracles.length, _weights.length);

        weights = PackedUint32ArrayLib.from(_weights);
    }

    function description() external pure override returns (OracleDescription.Description memory) {
        return OracleDescription.WeightedAggregator();
    }

    function _aggregateQuotes(uint256[] memory quotes, PackedUint32Array successMask)
        internal
        view
        override
        returns (uint256)
    {
        PackedUint32Array _weights = weights;
        uint256 totalWeight = _weights.mask(successMask).sum();
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
            weightedSum += quotes[i] * _weights.get(j);
            unchecked {
                ++i;
            }
        }

        return weightedSum / totalWeight;
    }
}
