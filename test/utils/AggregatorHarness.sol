// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {TryCallOracleHarness} from "test/utils/TryCallOracleHarness.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";

contract AggregatorHarness is Aggregator {
    constructor(address[] memory _oracles, uint256 _quorum) Aggregator(_oracles, _quorum) {}

    function description() external pure override returns (OracleDescription.Description memory) {}

    function _aggregateQuotes(uint256[] memory) internal pure override returns (uint256) {
        return 0;
    }
}
