// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FeedRegistry} from "src/FeedRegistry.sol";
import {IOracleFactory} from "src/interfaces/IOracleFactory.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title BaseAdapterFactory
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Abstract adapter factory with a governable feed registry.
abstract contract BaseAdapterFactory is FeedRegistry, IOracleFactory {
    /// @inheritdoc IOracleFactory
    mapping(address oracle => DeploymentInfo) public deployments;

    /// Deploy BaseAdapterFactory.
    /// @param _governor The address of the FeedRegistry governor.
    constructor(address _governor) FeedRegistry(_governor) {}

    /// @inheritdoc IOracleFactory
    function deploy(address base, address quote, bytes calldata extraData) external returns (address) {
        address oracle = _deployAdapter(base, quote, extraData);
        deployments[oracle] = DeploymentInfo(msg.sender, uint48(block.timestamp));
        return oracle;
    }

    /// @notice Deploy a PriceOracle using the factory.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @param extraData Abi-encoded extra deployment arguments.
    /// @return The deployed PriceOracle.
    function _deployAdapter(address base, address quote, bytes calldata extraData) internal virtual returns (address);
}
