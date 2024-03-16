// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Governable} from "src/lib/Governable.sol";
import {IAdapterFactory} from "src/interfaces/IAdapterFactory.sol";

contract OracleFactory is Governable {
    mapping(address factory => bool) public enabledFactories;
    mapping(address base => mapping(address quote => address)) public singletonAdapters;

    struct DeploymentInfo {
        address factory;
        address base;
        address quote;
        bytes extraData;
    }

    mapping(address adapter => DeploymentInfo) public deployedAdapters;

    event FactorySet(address factory, bool isEnabled);
    event AdapterDeployed(
        address indexed adapter, address indexed factory, address base, address quote, bytes extraData
    );

    error DeploymentFailed();
    error FactoryUnauthorized();

    constructor(address _governor) Governable(_governor) {}

    function setFactory(address factory, bool isEnabled) external onlyGovernor {
        enabledFactories[factory] = isEnabled;
        emit FactorySet(factory, isEnabled);
    }

    function deployAdapter(address factory, address base, address quote, bytes calldata extraData)
        external
        returns (address)
    {
        if (!enabledFactories[factory]) revert FactoryUnauthorized();
        address adapter = IAdapterFactory(factory).deploy(base, quote, extraData);
        if (adapter == address(0)) revert DeploymentFailed();
        deployedAdapters[adapter] = DeploymentInfo(factory, base, quote, extraData);
        emit AdapterDeployed(adapter, factory, base, quote, extraData);
        return adapter;
    }

    function setSingletonAdapter(address base, address quote, address oracle, bool populateInverse)
        external
        onlyGovernor
    {
        singletonAdapters[base][quote] = oracle;
        if (populateInverse) singletonAdapters[quote][base] = oracle;
    }
}
