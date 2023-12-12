// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {AggregatorFunctions} from "src/strategy/aggregator/AggregatorFunctions.sol";

contract AggregatorFunctionsHarness {
    function max(uint256[] memory quotes) external pure returns (uint256) {
        return AggregatorFunctions.max(quotes);
    }

    function mean(uint256[] memory quotes) external pure returns (uint256) {
        return AggregatorFunctions.mean(quotes);
    }

    function median(uint256[] memory quotes) external pure returns (uint256) {
        return AggregatorFunctions.median(quotes);
    }

    function min(uint256[] memory quotes) external pure returns (uint256) {
        return AggregatorFunctions.min(quotes);
    }
}
