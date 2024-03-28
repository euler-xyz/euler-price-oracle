// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {BaseAdapterFactory, Errors} from "src/adapter/BaseAdapterFactory.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";

/// @title PythFactory
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Chainlink oracle factory with a feed registry.
contract PythFactory is BaseAdapterFactory {
    /// @notice The address of the Pyth oracle proxy.
    address public immutable pyth;

    /// @notice Deploy PythFactory.
    /// @param _governor The address of the FeedRegistry governor.
    /// @param _pyth The address of the Pyth oracle proxy.
    constructor(address _governor, address _pyth) BaseAdapterFactory(_governor) {
        pyth = _pyth;
    }

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
        return address(new PythOracle(pyth, base, quote, feed, maxStaleness));
    }
}
