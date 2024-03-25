// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Governable} from "src/lib/Governable.sol";
import {IOracleFactory} from "src/interfaces/IOracleFactory.sol";

contract OracleFactory is Governable {
    mapping(address factory => bool) public enabledFactories;
    mapping(address base => mapping(address quote => address)) public singletonOracles;

    struct DeploymentInfo {
        address factory;
        address base;
        address quote;
        bytes extraData;
    }

    mapping(address oracle => DeploymentInfo) public deployedOracles;

    event FactoryStatusSet(address indexed factory, bool indexed isEnabled);
    event OracleDeployed(address indexed oracle, address indexed factory, address base, address quote, bytes extraData);
    event SingletonOracleSet(address indexed oracle, address base, address quote);

    error DeploymentFailed();
    error FactoryUnauthorized();

    constructor(address _governor) Governable(_governor) {}

    function setFactoryStatus(address factory, bool isEnabled) external onlyGovernor {
        enabledFactories[factory] = isEnabled;
        emit FactoryStatusSet(factory, isEnabled);
    }

    function deployOracle(address factory, address base, address quote, bytes calldata extraData)
        external
        returns (address)
    {
        if (!enabledFactories[factory]) revert FactoryUnauthorized();
        address oracle = IOracleFactory(factory).deploy(base, quote, extraData);
        if (oracle == address(0)) revert DeploymentFailed();
        deployedOracles[oracle] = DeploymentInfo(factory, base, quote, extraData);
        emit OracleDeployed(oracle, factory, base, quote, extraData);
        return oracle;
    }

    function setSingletonOracle(address base, address quote, address oracle) external onlyGovernor {
        singletonOracles[base][quote] = oracle;
        singletonOracles[quote][base] = oracle;
        emit SingletonOracleSet(oracle, base, quote);
    }
}
