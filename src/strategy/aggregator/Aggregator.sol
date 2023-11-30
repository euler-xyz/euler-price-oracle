// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseOracle} from "src/BaseOracle.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {PackedUint32Array, PackedUint32ArrayLib} from "src/lib/PackedUint32Array.sol";
import {TryCallOracle} from "src/strategy/TryCallOracle.sol";

/// @author totomanov
/// @notice Reduce an array of quotes by applying a statistical function.
abstract contract Aggregator is BaseOracle, TryCallOracle, ImmutableAddressArray {
    uint256 public immutable quorum;

    /// @param _oracles The list of oracles to call simultaneously.
    /// @param _quorum The minimum number of valid answers required.
    /// If the quorum is not met then `getQuote` and `getQuotes` will revert.
    constructor(address[] memory _oracles, uint256 _quorum) ImmutableAddressArray(_oracles) {
        if (_quorum == 0) revert Errors.Aggregator_QuorumZero();
        if (_quorum > cardinality) revert Errors.Aggregator_QuorumTooLarge(_quorum, cardinality);

        quorum = _quorum;
    }

    /// @inheritdoc IPriceOracle
    /// @dev Constructs a success mask which is useful to determine the indices of failed oracles.
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    /// @inheritdoc IPriceOracle
    /// @dev Constructs a success mask which is useful to determine the indices of failed oracles.
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 answer = _getQuote(inAmount, base, quote);
        return (answer, answer);
    }

    /// @inheritdoc IPriceOracle
    function description() external pure virtual returns (OracleDescription.Description memory);

    /// @dev Apply the aggregation algorithm.
    function _aggregateQuotes(uint256[] memory, PackedUint32Array) internal view virtual returns (uint256);

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        uint256[] memory answers = new uint256[](cardinality);
        uint256 numAnswers;
        PackedUint32Array successMask;

        for (uint256 i = 0; i < cardinality;) {
            IPriceOracle oracle = IPriceOracle(_arrayGet(i));
            (bool success, uint256 answer) = _tryGetQuote(oracle, inAmount, base, quote);

            unchecked {
                if (success) {
                    successMask = successMask.set(i, PackedUint32ArrayLib.MAX_VALUE);
                    answers[numAnswers] = answer;
                    ++numAnswers;
                }
                ++i;
            }
        }

        if (numAnswers < quorum) revert Errors.Aggregator_QuorumNotReached(numAnswers, quorum);

        assembly {
            // update the length of answer
            // this is safe because new length <= initial length
            mstore(answers, numAnswers)
        }

        // custom aggregation logic here
        return _aggregateQuotes(answers, successMask);
    }
}
