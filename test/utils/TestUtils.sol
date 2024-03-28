// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FeedIdentifier} from "src/lib/FeedIdentifier.sol";

function boundAddr(address addr) pure returns (address) {
    if (
        uint160(addr) < 256 || addr == 0x4e59b44847b379578588920cA78FbF26c0B4956C
            || addr == 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D || addr == 0x000000000000000000636F6e736F6c652e6c6f67
            || addr == 0x5615dEB798BB3E4dFa0139dFa1b3D433Cc23b72f || addr == 0x104fBc016F4bb334D775a19E8A6510109AC63E00
            || addr == 0x4f81992FCe2E1846dD528eC0102e6eE1f61ed3e2
    ) return address(uint160(addr) + 256);

    return addr;
}

function distinct(address a, address b, address c) pure returns (bool) {
    return a != b && a != c && b != c;
}

function distinct(address a, address b, address c, address d) pure returns (bool) {
    return a != b && a != c && a != d && b != c && b != d && c != d;
}

function distinct(address a, address b, address c, address d, address e) pure returns (bool) {
    return a != b && a != c && a != d && a != e && b != c && b != d && b != e && c != d && c != e && d != e;
}

function arrOf(address e0) pure returns (address[] memory arr) {
    arr = new address[](1);
    arr[0] = e0;
}

function arrOf(address e0, address e1) pure returns (address[] memory arr) {
    arr = new address[](2);
    arr[0] = e0;
    arr[1] = e1;
}

function arrOf(address e0, address e1, address e2) pure returns (address[] memory arr) {
    arr = new address[](3);
    arr[0] = e0;
    arr[1] = e1;
    arr[2] = e2;
}

function arrOf(bytes32 e0) pure returns (bytes32[] memory arr) {
    arr = new bytes32[](1);
    arr[0] = e0;
}

function arrOf(bytes32 e0, bytes32 e1) pure returns (bytes32[] memory arr) {
    arr = new bytes32[](2);
    arr[0] = e0;
    arr[1] = e1;
}

function arrOf(bytes32 e0, bytes32 e1, bytes32 e2) pure returns (bytes32[] memory arr) {
    arr = new bytes32[](3);
    arr[0] = e0;
    arr[1] = e1;
    arr[2] = e2;
}

function arrOf(FeedIdentifier e0) pure returns (FeedIdentifier[] memory arr) {
    arr = new FeedIdentifier[](1);
    arr[0] = e0;
}

function arrOf(FeedIdentifier e0, FeedIdentifier e1) pure returns (FeedIdentifier[] memory arr) {
    arr = new FeedIdentifier[](2);
    arr[0] = e0;
    arr[1] = e1;
}

function arrOf(FeedIdentifier e0, FeedIdentifier e1, FeedIdentifier e2) pure returns (FeedIdentifier[] memory arr) {
    arr = new FeedIdentifier[](3);
    arr[0] = e0;
    arr[1] = e1;
    arr[2] = e2;
}
