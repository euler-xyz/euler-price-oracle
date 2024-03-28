// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IOracleFactory} from "src/interfaces/IOracleFactory.sol";

contract StubOracleFactory is IOracleFactory {
    bool doRevert;
    address deploymentAddress;

    function setRevert(bool _doRevert) external {
        doRevert = _doRevert;
    }

    function setDeploymentAddress(address _deploymentAddress) external {
        deploymentAddress = _deploymentAddress;
    }

    function deploy(address, address, bytes calldata) external view returns (address) {
        if (doRevert) revert("oops");
        return deploymentAddress;
    }

    function deployments(address oracle) external view returns (address, uint48) {}
}
