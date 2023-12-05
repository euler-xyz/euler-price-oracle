// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {GenericFactory} from "./GenericFactory.sol";

contract OracleFactory is GenericFactory {
    mapping(address oracle => OracleConfig) oracleLookup;

    struct OracleConfig {
        bool upgradeable;
    }

    constructor(address admin) GenericFactory(admin) {}

    function deploy(bool upgradeable, bytes memory trailingData) external nonReentrant returns (address) {
        address proxy = createProxy(upgradeable, trailingData);

        oracleLookup[proxy] = OracleConfig({upgradeable: upgradeable});

        return proxy;
    }
}
