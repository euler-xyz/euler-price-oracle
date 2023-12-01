// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {GenericFactory} from "./GenericFactory.sol";

contract OracleFactory is GenericFactory {
    struct OracleConfig {
        address asset;
        address riskManager;
    }

    mapping(address oracle => OracleConfig) oracleLookup;

    constructor(address admin) GenericFactory(admin) {}

    function activate(bool upgradeable, address asset, address riskManager) external nonReentrant returns (address) {
        address proxy = createProxy(upgradeable, abi.encodePacked(asset, riskManager));

        oracleLookup[proxy] = OracleConfig({asset: asset, riskManager: riskManager});

        return proxy;
    }
}
