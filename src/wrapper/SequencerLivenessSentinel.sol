// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {AggregatorV3Interface} from "src/adapter/chainlink/AggregatorV3Interface.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title SequencerLivenessSentinel
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Oracle that bundles an L2 sequencer liveness check with the price.
contract SequencerLivenessSentinel is IPriceOracle {
    /// @inheritdoc IPriceOracle
    string public constant name = "SequencerLivenessSentinel";
    /// @notice The address of the wrapped oracle.
    address public immutable wrappedOracle;
    /// @notice The address of the Chainlink L2 sequencer uptime feed.
    /// @dev https://docs.chain.link/data-feeds/l2-sequencer-feeds
    address public immutable chainlinkSequencerUptimeFeed;
    /// @notice The grace period after a sequencer is up.
    /// @dev https://docs.chain.link/data-feeds/l2-sequencer-feeds#example-code
    uint256 public immutable gracePeriod;

    /// @notice Deploy an SequencerLivenessSentinel.
    /// @param _wrappedOracle The address of the wrapped oracle.
    /// @param _chainlinkSequencerUptimeFeed The address of the Chainlink L2 sequencer uptime feed.
    /// @param _gracePeriod The grace period after a sequencer is up.
    constructor(address _wrappedOracle, address _chainlinkSequencerUptimeFeed, uint256 _gracePeriod) {
        wrappedOracle = _wrappedOracle;
        chainlinkSequencerUptimeFeed = _chainlinkSequencerUptimeFeed;
        gracePeriod = _gracePeriod;
    }

    /// @notice Get a quote from `wrappedOracle` after checking that the L2 sequencer is up.
    /// @inheritdoc IPriceOracle
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        _checkLiveness();
        return IPriceOracle(wrappedOracle).getQuote(inAmount, base, quote);
    }

    /// @notice Get a quote from `wrappedOracle` after checking that the L2 sequencer is up.
    /// @inheritdoc IPriceOracle
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        _checkLiveness();
        return IPriceOracle(wrappedOracle).getQuotes(inAmount, base, quote);
    }

    function _checkLiveness() internal view {
        // `startedAt` indicates when the sequencer last changed status.
        (, int256 answer, uint256 startedAt,,) = AggregatorV3Interface(chainlinkSequencerUptimeFeed).latestRoundData();
        // Check that the sequencer is up.
        if (answer != 0) revert Errors.PriceOracle_InvalidAnswer();
        // Check that the grace period has elapsed.
        if (block.timestamp - startedAt <= gracePeriod) revert Errors.PriceOracle_InvalidAnswer();
    }
}
