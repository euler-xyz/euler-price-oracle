// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Ownable} from "@solady/auth/Ownable.sol";
import {LibClone} from "@solady/utils/LibClone.sol";

contract OracleFactory is Ownable {
    struct ResolutionStrategy {
        address referenceAsset;
        uint256 oracleImplementationId;
        bytes initData;
    }

    struct OracleStrategy {
        address[] base;
        address quote;
        ResolutionStrategy[] resolutionStrategies;
    }

    struct OracleConfiguration {
        OracleStrategy[] strategies;
    }

    address[] public allowedOracles;
    mapping(address vault => address oracle) public deployedOracles;

    event OracleDeployed(address indexed vault, address indexed oracle);

    error OracleAlreadyDeployed(address vault, address oracle);

    constructor(address _owner) {
        _initializeOwner(_owner);
    }

    /// @dev example constructions for oracle o(A,Z)
    /// e.g. o(A,Z) = o(A,B) * o(B,C) * o(C,Z), reference assets B,C
    /// e.g. o(A,Z) = o(A,R) / o(Z,R), reference asset R
    function deploy(address vault, OracleConfiguration memory config) public {
        address oracle = deployedOracles[vault];
        if (oracle != address(0)) revert OracleAlreadyDeployed(vault, oracle);
    }

    function addImplementation(address oracle) public onlyOwner {
        allowedOracles.push(oracle);
    }
}
