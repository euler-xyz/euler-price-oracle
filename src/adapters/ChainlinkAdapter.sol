// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {AggregatorV3Interface} from "src/interfaces/AggregatorV3Interface.sol";

contract ChainlinkAdapter {
    AggregatorV3Interface public aggregatorV3;
    uint256 public constant MAX_STALENESS = 1 days;

    error ChainlinkPriceOracle_CallReverted();
    error ChainlinkPriceOracle_InvalidAnswer(int256 answer);
    error ChainlinkPriceOracle_TooStale(uint256 staleness, uint256 maxStaleness);

    constructor(address _aggregatorV3) {
        aggregatorV3 = AggregatorV3Interface(_aggregatorV3);
    }


    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
    }

    function _getChainlinkPrice() private view returns (uint256) {
        try aggregatorV3.latestRoundData() returns (uint80, int256 answer, uint256, uint256 updatedAt, uint80) {
            if (answer <= 0) revert ChainlinkPriceOracle_InvalidAnswer(answer);

            uint256 staleness = block.timestamp - updatedAt;
            if (staleness >= MAX_STALENESS) {
                revert ChainlinkPriceOracle_TooStale(staleness, MAX_STALENESS);
            }

            return uint256(answer);
        } catch {
            revert ChainlinkPriceOracle_CallReverted();
        }
    }
}
