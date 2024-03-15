// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {FeedRegistry} from "src/FeedRegistry.sol";
import {Errors} from "src/lib/Errors.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";

contract PythFactory is FeedRegistry {
    address public immutable pyth;

    struct DeploymentInfo {
        address deployer;
        uint48 deployedAt;
    }

    mapping(address oracle => DeploymentInfo) public deployments;

    constructor(address _governor, address _pyth) FeedRegistry(_governor) {
        pyth = _pyth;
    }

    function deploy(address base, address quote, uint256 maxStaleness) external returns (address) {
        bytes32 feedId = feeds[base][quote];
        if (feedId == 0) revert Errors.PriceOracle_InvalidConfiguration();
        address oracle = address(new PythOracle(pyth, base, quote, feedId, maxStaleness, false));
        deployments[oracle] = DeploymentInfo(msg.sender, uint48(block.timestamp));
        return oracle;
    }

    function isDeployer(address oracle) external view returns (bool) {
        return deployments[oracle].deployer != address(0);
    }
}
