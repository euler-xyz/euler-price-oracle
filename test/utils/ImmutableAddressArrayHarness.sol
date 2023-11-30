// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";

contract ImmutableAddressArrayHarness is ImmutableAddressArray {
    constructor(address[] memory arr) ImmutableAddressArray(arr) {}

    function getCardinality() external view returns (uint256) {
        return cardinality;
    }

    function get(uint256 i) external view returns (address) {
        return _arrayGet(i);
    }
}
