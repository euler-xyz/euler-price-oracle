// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {LibSort} from "@solady/utils/LibSort.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";
import {AggregatorAlgorithms} from "src/strategy/aggregator/AggregatorAlgorithms.sol";

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
            algorithm = AggregatorAlgorithms.max;
        } else if (_algorithm == Algorithm.MEAN) {
            algorithm = AggregatorAlgorithms.mean;
        } else if (_algorithm == Algorithm.MEDIAN) {
            algorithm = AggregatorAlgorithms.median;
        } else if (_algorithm == Algorithm.MIN) {
            algorithm = AggregatorAlgorithms.min;
        } else {
            revert Errors.Aggregator_InvalidAlgorithm();
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
}
