// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {BaseAdapterFactory} from "src/adapter/BaseAdapterFactory.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";
import {FeedRegistry} from "src/FeedRegistry.sol";
import {Errors} from "src/lib/Errors.sol";

contract RedstoneCoreFactory is BaseAdapterFactory {
    constructor(address _governor) BaseAdapterFactory(_governor, FeedRegistry.FeedType.Bytes32) {}

    function deploy(address base, address quote, bytes calldata extraData) external override returns (address) {
        uint256 maxStaleness = abi.decode(extraData, (uint256));
        bytes32 feed = getBytes32Feed(base, quote);
        address oracle = address(new RedstoneCoreOracle(base, quote, feed, maxStaleness));
        deployments[oracle] = DeploymentInfo(msg.sender, uint48(block.timestamp));
        return oracle;
    }
}
