// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {MaxAggregator} from "src/strategy/aggregator/MaxAggregator.sol";

contract MaxAggregatorHarness is MaxAggregator {
    constructor(address[] memory _oracles, uint256 _quorum) MaxAggregator(_oracles, _quorum) {}

    function aggregateQuotes(uint256[] memory quotes, PackedUint32Array mask) public pure returns (uint256) {
        return _aggregateQuotes(quotes, mask);
    }
}
