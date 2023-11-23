// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {PackedUint32Array, PackedUint32ArrayLib} from "src/lib/PackedUint32Array.sol";
import {TryCallOracle} from "src/strategy/TryCallOracle.sol";

abstract contract Aggregator is TryCallOracle, ImmutableAddressArray {
    uint256 public immutable quorum;

    error QuorumNotReached(uint256 count, uint256 quorum);
    error QuorumTooLarge(uint256 quorum, uint256 maxQuorum);
    error QuorumZero();

    constructor(address[] memory _oracles, uint256 _quorum) ImmutableAddressArray(_oracles) {
        if (_quorum == 0) revert QuorumZero();
        if (_quorum > cardinality) revert QuorumTooLarge(_quorum, cardinality);

        quorum = _quorum;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        uint256[] memory answers = new uint256[](cardinality);
        uint256 numAnswers;
        PackedUint32Array successMask;

        for (uint256 i = 0; i < cardinality;) {
            IPriceOracle oracle = IPriceOracle(_get(i));
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

        if (numAnswers < quorum) revert QuorumNotReached(numAnswers, quorum);

        assembly {
            // update the length of answer
            // this is safe because new length <= initial length
            mstore(answers, numAnswers)
        }

        // custom aggregation logic here
        return _aggregateQuotes(answers, successMask);
    }

    function description() external pure virtual returns (OracleDescription.Description memory);

    function _aggregateQuotes(uint256[] memory, PackedUint32Array) internal view virtual returns (uint256);
}
