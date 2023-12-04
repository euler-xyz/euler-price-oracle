// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {TryCallOracleHarness} from "test/utils/TryCallOracleHarness.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";

contract AggregatorHarness is Aggregator {
    function description() external pure override returns (OracleDescription.Description memory) {}

    function _aggregateQuotes(uint256[] memory, PackedUint32Array) internal pure override returns (uint256) {
        return 0;
    }
}
