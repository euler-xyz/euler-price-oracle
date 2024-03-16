// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FeedRegistry} from "src/FeedRegistry.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";
import {IAdapterFactory} from "src/interfaces/IAdapterFactory.sol";
import {Errors} from "src/lib/Errors.sol";

contract PythFactory is FeedRegistry, IAdapterFactory {
    address public immutable pyth;

    struct DeploymentInfo {
        address deployer;
        uint48 deployedAt;
    }

    mapping(address oracle => DeploymentInfo) public deployments;

    constructor(address _governor, address _pyth) FeedRegistry(_governor) {
        pyth = _pyth;
    }

    function deploy(address base, address quote, bytes calldata extraData) external returns (address) {
        uint256 maxStaleness = abi.decode(extraData, (uint256));
        bytes32 feedId = feeds[base][quote];
        if (feedId == 0) revert Errors.PriceOracle_InvalidConfiguration();
        address oracle = address(new PythOracle(pyth, base, quote, feedId, maxStaleness));
        deployments[oracle] = DeploymentInfo(msg.sender, uint48(block.timestamp));
        return oracle;
    }
}
