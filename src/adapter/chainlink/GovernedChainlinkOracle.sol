// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract GovernedChainlinkOracle is ChainlinkOracle {
    event ConfigRemoved(address indexed base, address indexed quote);

    constructor(address _feedRegistry, address _weth) ChainlinkOracle(_feedRegistry, _weth) {}

    function setConfig(ChainlinkOracle.ConfigParams memory params) external onlyGovernor {
        bool isEnabled = feedRegistry.isFeedEnabled(params.feed);
        if (!isEnabled) revert Errors.Chainlink_FeedNotEnabled(params.feed);

        _setConfig(params);
    }

    function removeConfig(address base, address quote) external onlyGovernor {
        delete configs[base][quote];
        delete configs[quote][base];

        emit ConfigRemoved(base, quote);
        emit ConfigRemoved(quote, base);
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.GovernedChainlinkOracle(uint256(DEFAULT_MAX_STALENESS), governor);
    }
}
