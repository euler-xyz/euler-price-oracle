// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FeedRegistry} from "src/FeedRegistry.sol";
import {IOracleFactory} from "src/interfaces/IOracleFactory.sol";

abstract contract BaseAdapterFactory is FeedRegistry, IOracleFactory {
    struct DeploymentInfo {
        address deployer;
        uint48 deployedAt;
    }

    mapping(address oracle => DeploymentInfo) public deployments;

    constructor(address _governor, FeedRegistry.FeedType _feedType) FeedRegistry(_governor, _feedType) {}

    function deploy(address base, address quote, bytes calldata extraData) external virtual returns (address);
}
