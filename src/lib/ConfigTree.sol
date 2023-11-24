// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

library TreeShapeLib {
    error OOB(uint256 pos);

    // function numChildren(bytes memory shape, uint256 pos) internal pure returns (uint256 c) {
    //     if (pos > shape.length) revert OOB(pos);

    //     assembly ("memory-safe") {
    //         let len := mload(shape)
    //         c := byte(add(add(len, 0x20), pos))
    //     }
    // }
}

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
