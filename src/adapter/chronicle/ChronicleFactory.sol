// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FeedAddressRegistry} from "src/FeedAddressRegistry.sol";
import {ChronicleOracle} from "src/adapter/chronicle/ChronicleOracle.sol";
import {IOracleFactory} from "src/interfaces/IOracleFactory.sol";
import {Errors} from "src/lib/Errors.sol";

contract ChronicleFactory is FeedAddressRegistry, IOracleFactory {
    struct DeploymentInfo {
        address deployer;
        uint48 deployedAt;
    }

    mapping(address oracle => DeploymentInfo) public deployments;

    constructor(address _governor) FeedAddressRegistry(_governor) {}

    function deploy(address base, address quote, bytes calldata extraData) external returns (address) {
        uint256 maxStaleness = abi.decode(extraData, (uint256));
        address feed = getFeed[base][quote];
        if (feed == address(0)) revert Errors.PriceOracle_InvalidConfiguration();
        address oracle = address(new ChronicleOracle(base, quote, feed, maxStaleness));
        deployments[oracle] = DeploymentInfo(msg.sender, uint48(block.timestamp));
        return oracle;
    }
}
