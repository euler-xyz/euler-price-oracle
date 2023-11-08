// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

function boundAddr(address addr) pure returns (address) {
    if (
        uint160(addr) < 256 || addr == 0x4e59b44847b379578588920cA78FbF26c0B4956C
            || addr == 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D || addr == 0x000000000000000000636F6e736F6c652e6c6f67
    ) return address(uint160(addr) + 256);

    return addr;
}
