// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

struct DeploymentConfig {
    bool doDeploy;
    address factory;
    address result;
    bytes initData;
}

struct DeploymentTree {
    bytes shape;
    DeploymentConfig[] configs;
}

library TreeLib {
    function walk(DeploymentTree memory tree) internal pure returns (DeploymentConfig memory) {}
}
