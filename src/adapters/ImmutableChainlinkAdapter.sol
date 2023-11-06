// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {FeedRegistryInterface} from "@chainlink/interfaces/FeedRegistryInterface.sol";

contract ImmutableChainlinkAdapter {
    uint256 public constant MAX_ROUND_DURATION = 1 hours;
    uint256 public constant MAX_STALENESS = 1 days;
    FeedRegistryInterface public immutable feedRegistry;

    error ChainlinkAdapter_CallReverted();
    error ChainlinkAdapter_InvalidAnswer(int256 answer);
    error ChainlinkAdapter_PriceTooStale(uint256 staleness, uint256 maxStaleness);
    error ChainlinkAdapter_RoundTooLong(uint256 duration, uint256 maxDuration);

    constructor(address _feedRegistry) {
        feedRegistry = FeedRegistryInterface(_feedRegistry);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        uint256 unitPrice = _getAnswer(base, quote);
        uint8 decimals = _getFeedDecimals(base, quote);
        uint256 outAmount = (inAmount * unitPrice) / 10 ** decimals;
        return outAmount;
    }

    function _getAnswer(address base, address quote) private view returns (uint256) {
        try feedRegistry.latestRoundData(base, quote) returns (
            uint80, int256 answer, uint256 startedAt, uint256 updatedAt, uint80
        ) {
            if (answer <= 0) revert ChainlinkAdapter_InvalidAnswer(answer);

            uint256 roundDuration = updatedAt - startedAt;
            if (roundDuration > MAX_ROUND_DURATION) {
                revert ChainlinkAdapter_RoundTooLong(roundDuration, MAX_ROUND_DURATION);
            }

            uint256 staleness = block.timestamp - updatedAt;
            if (staleness >= MAX_STALENESS) {
                revert ChainlinkAdapter_PriceTooStale(staleness, MAX_STALENESS);
            }

            return uint256(answer);
        } catch {
            revert ChainlinkAdapter_CallReverted();
        }
    }

    function _getFeedDecimals(address base, address quote) private view returns (uint8) {
        try feedRegistry.decimals(base, quote) returns (uint8 decimals) {
            return decimals;
        } catch {
            revert ChainlinkAdapter_CallReverted();
        }
    }
}
