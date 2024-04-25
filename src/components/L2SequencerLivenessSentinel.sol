// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {BaseAdapter, Errors, IPriceOracle} from "src/adapter/BaseAdapter.sol";
import {AggregatorV3Interface} from "src/adapter/chainlink/AggregatorV3Interface.sol";

/// @title L2SequencerLivenessSentinel
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Oracle that bundles an L2 sequencer liveness check with the price.
contract L2SequencerLivenessSentinel is BaseAdapter {
    /// @notice The address of the base asset.
    address public immutable base;
    /// @notice The address of the quote asset.
    address public immutable quote;
    /// @notice The address of the oracle.
    address public immutable oracle;
    /// @notice The address of the Chainlink L2 sequencer uptime feed.
    /// @dev https://docs.chain.link/data-feeds/l2-sequencer-feeds
    address public immutable chainlinkL2SequencerUptimeFeed;

    /// @notice Deploy an L2SequencerLivenessSentinel.
    /// @param _base The address of the base asset.
    /// @param _quote The address of the quote asset.
    /// @param _oracle The oracle to use for the price.
    /// @param _chainlinkL2SequencerUptimeFeed The address of the Chainlink L2 sequencer uptime feed.
    constructor(address _base, address _quote, address _oracle, address _chainlinkL2SequencerUptimeFeed) {
        base = _base;
        quote = _quote;
        oracle = _oracle;
        chainlinkL2SequencerUptimeFeed = _chainlinkL2SequencerUptimeFeed;
    }

    /// @notice Get a quote by the oracle after checking that the L2 sequencer is up.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount by chaining the cross oracles.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        (, int256 answer,, uint256 updatedAt,) = AggregatorV3Interface(feed).latestRoundData();
        if (answer != 0) revert Errors.PriceOracle_InvalidAnswer();
        return IPriceOracle(oracle).getQuote(inAmount, _base, _quote);
    }
}
