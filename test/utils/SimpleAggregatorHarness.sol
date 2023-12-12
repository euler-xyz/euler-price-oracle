// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {SimpleAggregator} from "src/strategy/aggregator/SimpleAggregator.sol";

contract SimpleAggregatorHarness is SimpleAggregator {
    constructor(address[] memory _oracles, uint256 _quorum, SimpleAggregator.Algorithm _algorithm)
        SimpleAggregator(_oracles, _quorum, _algorithm)
    {}

    function aggregateQuotes(uint256[] memory quotes) public view returns (uint256) {
        return _aggregateQuotes(quotes);
    }
}
