// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";

contract ForkTest is Test {
    uint256 constant ETHEREUM_FORK_BLOCK = 18515555;
    uint256 ethereumFork;

    function _setUpFork() public {
        string memory ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL");
        ethereumFork = vm.createFork(ETHEREUM_RPC_URL);
        vm.selectFork(ethereumFork);
        vm.roll(ETHEREUM_FORK_BLOCK);
    }
}
