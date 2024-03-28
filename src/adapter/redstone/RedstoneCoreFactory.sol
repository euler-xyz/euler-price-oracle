// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {BaseAdapterFactory, Errors} from "src/adapter/BaseAdapterFactory.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";

/// @title RedstoneCoreFactory
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Redstone Core oracle factory with a feed registry.
contract RedstoneCoreFactory is BaseAdapterFactory {
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
        bytes32 feed = getFeed[base][quote].toBytes32();
        if (feed == 0) revert Errors.PriceOracle_InvalidConfiguration();
        return address(new RedstoneCoreOracle(base, quote, feed, maxStaleness));
    }
}
