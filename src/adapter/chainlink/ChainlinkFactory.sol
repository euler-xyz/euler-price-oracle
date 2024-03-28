// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {BaseAdapterFactory, Errors} from "src/adapter/BaseAdapterFactory.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";

/// @title ChainlinkFactory
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Chainlink oracle factory with a feed registry.
contract ChainlinkFactory is BaseAdapterFactory {
    /// @notice Deploy ChainlinkFactory.
    /// @param _governor The address of the FeedRegistry governor.
    constructor(address _governor) BaseAdapterFactory(_governor) {}

    /// @inheritdoc BaseAdapterFactory
    /// @dev Extra data must be abi-encoded maxStaleness.
    function _deployAdapter(address base, address quote, bytes calldata extraData)
        internal
        override
        returns (address)
    {
        uint256 maxStaleness = abi.decode(extraData, (uint256));
        address feed = getFeed[base][quote].toAddress();
        if (feed == address(0)) revert Errors.OracleFactory_NoFeed(base, quote);
        return address(new ChainlinkOracle(base, quote, feed, maxStaleness));
    }
}
