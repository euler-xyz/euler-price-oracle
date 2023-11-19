// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {ChainlinkOracle} from "src/chainlink/ChainlinkOracle.sol";
import {OracleDescription} from "src/interfaces/OracleDescription.sol";

contract ImmutableChainlinkOracle is ChainlinkOracle {
    constructor(address _feedRegistry, address _weth) ChainlinkOracle(_feedRegistry, _weth) {}

    function initConfig(address base, address quote) external {
        _initConfig(base, quote);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.Description({
            algorithm: OracleDescription.Algorithm.VWAP,
            authority: OracleDescription.Authority.IMMUTABLE,
            paymentModel: OracleDescription.PaymentModel.FREE,
            requestModel: OracleDescription.RequestModel.PUSH,
            configuration: OracleDescription.Configuration({
                maxStaleness: DEFAULT_MAX_STALENESS,
                governor: address(0),
                supportsBidAskSpread: false
            })
        });
    }
}
