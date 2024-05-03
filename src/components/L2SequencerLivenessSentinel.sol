// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {BaseAdapter, Errors, IPriceOracle} from "src/adapter/BaseAdapter.sol";
import {AggregatorV3Interface} from "src/adapter/chainlink/AggregatorV3Interface.sol";

/// @title L2SequencerLivenessSentinel
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Oracle that bundles an L2 sequencer liveness check with the price.
contract L2SequencerLivenessSentinel is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "L2SequencerLivenessSentinel";
    /// @notice The address of the oracle.
    address public immutable oracle;
    /// @notice The address of the Chainlink L2 sequencer uptime feed.
    /// @dev https://docs.chain.link/data-feeds/l2-sequencer-feeds
    address public immutable chainlinkL2SequencerUptimeFeed;
    /// @notice The grace period after a sequencer is up.
    /// @dev https://docs.chain.link/data-feeds/l2-sequencer-feeds#example-code
    uint256 public immutable gracePeriod;

    /// @notice Deploy an L2SequencerLivenessSentinel.
    /// @param _oracle The oracle to use for the price.
    /// @param _chainlinkL2SequencerUptimeFeed The address of the Chainlink L2 sequencer uptime feed.
    /// @param _gracePeriod The grace period after a sequencer is up.
    constructor(address _oracle, address _chainlinkL2SequencerUptimeFeed, uint256 _gracePeriod) {
        oracle = _oracle;
        chainlinkL2SequencerUptimeFeed = _chainlinkL2SequencerUptimeFeed;
        gracePeriod = _gracePeriod;
    }

    /// @notice Get a quote from `oracle` after checking that the L2 sequencer is up.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @return The converted amount by `oracle`.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        // `startedAt` indicates when the sequencer changed status.
        (, int256 answer, uint256 startedAt,,) = AggregatorV3Interface(chainlinkL2SequencerUptimeFeed).latestRoundData();
        // Check that the sequencer is up.
        if (answer != 0) revert Errors.PriceOracle_InvalidAnswer();
        // Check that the grace period has elapsed.
        if (block.timestamp - startedAt <= gracePeriod) revert Errors.PriceOracle_InvalidAnswer();
        return IPriceOracle(oracle).getQuote(inAmount, base, quote);
    }
}
