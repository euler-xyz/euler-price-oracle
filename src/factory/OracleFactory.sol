// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

contract OracleFactory {
    struct Configuration {
        address base;
        address quote;
    }

    function deploy(Configuration memory config) public {}
}
