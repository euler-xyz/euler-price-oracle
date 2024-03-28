// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

/// @title IOracleFactory
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Common OracleFactory interface.
interface IOracleFactory {
    /// @notice Oracle deployment metadata.
    /// @param deployer The address that initiated the deployment.
    /// @param deployedAt The timestamp of the deployment.
    struct DeploymentInfo {
        address deployer;
        uint48 deployedAt;
    }

    /// @notice Deploy a PriceOracle using the factory.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @param extraData Abi-encoded extra deployment arguments.
    /// @return The deployed PriceOracle.
    function deploy(address base, address quote, bytes calldata extraData) external returns (address);
    /// @notice Query oracle deployment metadata.
    /// @param oracle The address of the deployed oracle.
    /// @return The address that initiated the deployment.
    /// @return The timestamp of the deployment.
    function deployments(address oracle) external view returns (address, uint48);
}
