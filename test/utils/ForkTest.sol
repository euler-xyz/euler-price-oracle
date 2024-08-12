// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

contract ForkTest is Test {
    uint256 constant ETHEREUM_FORK_BLOCK = 18888888;
    uint256 ethereumFork;
    uint256 arbitrumFork;

    function _setUpFork() public {
        _setUpFork(ETHEREUM_FORK_BLOCK);
    }

    function _setUpFork(uint256 blockNumber) public {
        _setUpForkLatest();
        vm.rollFork(blockNumber);
    }

    function _setUpForkLatest() public {
        string memory ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL");
        ethereumFork = vm.createFork(ETHEREUM_RPC_URL);
        vm.selectFork(ethereumFork);
    }

    function _setUpArbitrumFork(uint256 blockNumber) public {
        _setUpArbitrumForkLatest();
        vm.rollFork(blockNumber);
    }

    function _setUpArbitrumForkLatest() public {
        string memory ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");
        arbitrumFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(arbitrumFork);
    }
}
