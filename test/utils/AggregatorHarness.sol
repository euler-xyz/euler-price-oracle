// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {TryCallOracleHarness} from "test/utils/TryCallOracleHarness.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";

contract AggregatorHarness is Aggregator {
    constructor(address[] memory _oracles, uint256 _quorum) Aggregator(_oracles, _quorum) {}

    function _aggregateQuotes(uint256[] memory, PackedUint32Array) internal pure override returns (uint256) {
        return 0;
    }
}
