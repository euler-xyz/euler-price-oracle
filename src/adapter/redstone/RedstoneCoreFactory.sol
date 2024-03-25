// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FeedRegistry} from "src/FeedRegistry.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";
import {IOracleFactory} from "src/interfaces/IOracleFactory.sol";
import {Errors} from "src/lib/Errors.sol";

contract RedstoneCoreFactory is FeedRegistry, IOracleFactory {
    struct DeploymentInfo {
        address deployer;
        uint48 deployedAt;
    }

    mapping(address oracle => DeploymentInfo) public deployments;

    constructor(address _governor) FeedRegistry(_governor) {}

    function deploy(address base, address quote, bytes calldata extraData) external returns (address) {
        uint256 maxStaleness = abi.decode(extraData, (uint256));
        bytes32 feedId = feeds[base][quote];
        if (feedId == 0) revert Errors.PriceOracle_InvalidConfiguration();
        address oracle = address(new RedstoneCoreOracle(base, quote, feedId, maxStaleness));
        deployments[oracle] = DeploymentInfo(msg.sender, uint48(block.timestamp));
        return oracle;
    }
}
