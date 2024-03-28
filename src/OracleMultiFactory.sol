// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Errors} from "src/lib/Errors.sol";
import {Governable} from "src/lib/Governable.sol";
import {IOracleFactory} from "src/interfaces/IOracleFactory.sol";

/// @title OracleMultiFactory
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Oracle meta-factory supporting individual factories and singletons.
contract OracleMultiFactory is Governable {
    /// @notice Deployment metadata for oracles.
    /// @param factory The oracle factory, must implement `IOracleFactory`. Zero if singleton.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @param extraData Abi-encoded extra deployment arguments. Empty if singleton.
    struct DeploymentInfo {
        address factory;
        address base;
        address quote;
        bytes extraData;
    }
    /// @notice Factories enabled by the governor.

    mapping(address factory => bool) public enabledFactories;
    /// @notice Oracles deployed by the factory or set by the governor.
    mapping(address oracle => DeploymentInfo) public deployedOracles;

    /// @notice Enable or disable a factory.
    /// @param factory The oracle factory, must implement `IOracleFactory`.
    /// @param isEnabled Boolean indicating whether the factory is enabled.
    event FactoryStatusSet(address indexed factory, bool indexed isEnabled);
    /// @notice Emitted when an oracle is deployed.
    /// @param oracle The deployed oracle.
    /// @param factory The oracle factory, must implement `IOracleFactory`.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @param extraData Abi-encoded extra deployment arguments.
    event OracleDeployed(address indexed oracle, address indexed factory, address base, address quote, bytes extraData);
    /// @notice Emitted when a singleton oracle is set.
    /// @param oracle The deployed oracle.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    event SingletonOracleSet(address indexed oracle, address base, address quote);

    /// @notice Deploy OracleMultiFactory.
    /// @param _governor Address of the contract governor.
    constructor(address _governor) Governable(_governor) {}

    /// @notice Enable or disable a factory.
    /// @param factory The oracle factory, must implement `IOracleFactory`.
    /// @param isEnabled Boolean indicating whether the factory is enabled.
    /// @dev Only callable by the governor.
    function setFactoryStatus(address factory, bool isEnabled) external onlyGovernor {
        enabledFactories[factory] = isEnabled;
        emit FactoryStatusSet(factory, isEnabled);
    }

    /// @notice Set an oracle as a singleton.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @param oracle The oracle to set as a singleton. Must implement `IPriceOracle`.
    /// @dev Only callable by the governor. Useful for exchange rate oracles e.g. LidoOracle.
    function setSingletonOracle(address base, address quote, address oracle) external onlyGovernor {
        if (deployedOracles[oracle].base != address(0)) revert Errors.OracleMultiFactory_OracleAlreadySet();
        deployedOracles[oracle] = DeploymentInfo(address(0), base, quote, "");
        emit SingletonOracleSet(oracle, base, quote);
    }

    /// @notice Function to deploy an oracle using a factory.
    /// @param factory The oracle factory, must implement `IOracleFactory`.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @param extraData Abi-encoded extra deployment arguments.
    /// @return Address of the deployed oracle contract.
    function deployWithFactory(address factory, address base, address quote, bytes calldata extraData)
        external
        returns (address)
    {
        if (!enabledFactories[factory]) revert Errors.OracleMultiFactory_FactoryUnauthorized();

        address oracle = IOracleFactory(factory).deploy(base, quote, extraData);
        if (oracle == address(0)) revert Errors.OracleMultiFactory_DeploymentFailed();

        deployedOracles[oracle] = DeploymentInfo(factory, base, quote, extraData);
        emit OracleDeployed(oracle, factory, base, quote, extraData);
        return oracle;
    }
}
