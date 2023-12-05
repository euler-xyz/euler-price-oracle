// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";
import {AggregatorFunctions} from "src/strategy/aggregator/AggregatorFunctions.sol";

/// @author totomanov
/// @notice Reduce an array of quotes by applying a statistical function.
/// @dev Supports max, mean, median, min. See {AggregatorFunctions}.
contract SimpleAggregator is Aggregator {
    enum Algorithm {
        MAX,
        MEAN,
        MEDIAN,
        MIN
    }

    /// @notice Deploy a new SimpleAggregator.
    /// @param _oracles The list of oracles to call simultaneously.
    /// @param _quorum The minimum number of valid answers required.
    /// If the quorum is not met then `getQuote` and `getQuotes` will revert.
    /// @param _algorithm The chosen aggregator algorithm. This is immutable.
    constructor(address[] memory _oracles, uint256 _quorum, Algorithm _algorithm) Aggregator(_oracles, _quorum) {
        if (_algorithm == Algorithm.MAX) {
            algorithm = AggregatorFunctions.max;
        } else if (_algorithm == Algorithm.MEAN) {
            algorithm = AggregatorFunctions.mean;
        } else if (_algorithm == Algorithm.MEDIAN) {
            algorithm = AggregatorFunctions.median;
        } else if (_algorithm == Algorithm.MIN) {
            algorithm = AggregatorFunctions.min;
        } else {
            revert Errors.Aggregator_AlgorithmInvalid();
        }
    }

    /// @dev Internal function pointer to the selected function in the AggregatorFunctions library.
    function(uint256[] memory, PackedUint32Array) view returns (uint256) internal algorithm;

    /// @inheritdoc Aggregator
    function description() external pure override returns (OracleDescription.Description memory) {
        return OracleDescription.SimpleAggregator();
    }

    /// @inheritdoc Aggregator
    function _aggregateQuotes(uint256[] memory quotes, PackedUint32Array mask)
        internal
        view
        override
        returns (uint256)
    {
        return algorithm(quotes, mask);
    }
}
