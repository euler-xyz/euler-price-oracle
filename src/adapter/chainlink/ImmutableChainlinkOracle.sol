// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract ImmutableChainlinkOracle is ChainlinkOracle {
    bool public immutable canIngestNewFeeds;

    error NotSupported();

    constructor(
        address _feedRegistry,
        address _weth,
        bool _canIngestNewFeeds,
        ChainlinkOracle.ConfigParams[] memory _initialConfigs
    ) ChainlinkOracle(_feedRegistry, _weth) {
        canIngestNewFeeds = _canIngestNewFeeds;

        uint256 numConfigs = _initialConfigs.length;
        for (uint256 i = 0; i < numConfigs;) {
            ChainlinkOracle.ConfigParams memory params = _initialConfigs[i];
            _setConfig(params);
            unchecked {
                ++i;
            }
        }
    }

    function initConfig(address base, address quote) external {
        if (!canIngestNewFeeds) revert NotSupported();
        _initConfig(base, quote);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.ImmutableChainlinkOracle(uint256(DEFAULT_MAX_STALENESS));
    }
}
