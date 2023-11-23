// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {OracleDescription} from "src/lib/OracleDescription.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";

contract MaxAggregator is Aggregator {
    constructor(address[] memory _oracles, uint256 _quorum) Aggregator(_oracles, _quorum) {}

    function description() external pure override returns (OracleDescription.Description memory) {
        return OracleDescription.MaxAggregator();
    }

    function _aggregateQuotes(uint256[] memory quotes, PackedUint32Array) internal pure override returns (uint256) {
        uint256 max;

        for (uint256 i = 0; i < quotes.length;) {
            if (quotes[i] > max) max = quotes[i];

            unchecked {
                ++i;
            }
        }

        return max;
    }
}
