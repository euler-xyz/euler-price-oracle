// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Ownable} from "@solady/auth/Ownable.sol";
import {ChainlinkOracle} from "src/chainlink/ChainlinkOracle.sol";
import {OracleDescription} from "src/interfaces/OracleDescription.sol";

contract GovernedChainlinkOracle is ChainlinkOracle, Ownable {
    event ConfigAdded(address indexed base, address indexed quote, address indexed feed);
    event ConfigRemoved(address indexed base, address indexed quote);

    error FeedNotEnabled(address feed);

    constructor(address _feedRegistry, address _weth, address _owner) ChainlinkOracle(_feedRegistry, _weth) {
        _initializeOwner(_owner);
    }

    function addConfig(address base, address quote, address feed, uint32 maxStaleness, uint32 maxDuration, bool inverse)
        external
        onlyOwner
    {
        bool isEnabled = feedRegistry.isFeedEnabled(feed);
        if (!isEnabled) revert FeedNotEnabled(feed);

        _setConfig(base, quote, feed, maxStaleness, maxDuration, inverse);

        emit ConfigAdded(base, quote, feed);
    }

    function removeConfig(address base, address quote) external onlyOwner {
        delete configs[base][quote];
        delete configs[quote][base];

        emit ConfigRemoved(base, quote);
        emit ConfigRemoved(quote, base);
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.Description({
            algorithm: OracleDescription.Algorithm.VWAP,
            authority: OracleDescription.Authority.GOVERNED,
            paymentModel: OracleDescription.PaymentModel.FREE,
            requestModel: OracleDescription.RequestModel.PUSH,
            configuration: OracleDescription.Configuration({
                maxStaleness: DEFAULT_MAX_STALENESS,
                governor: owner(),
                supportsBidAskSpread: false
            }),
            children: new address[](0)
        });
    }
}
