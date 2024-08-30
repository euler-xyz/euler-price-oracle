// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {REDSTONE_ETH_USD_FEED, REDSTONE_ETHX_USD_FEED} from "test/adapter/redstone/RedstoneFeeds.sol";
import {WETH, USDC, ETHX, USD} from "test/utils/ArbitrumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {RedstoneCoreArbitrumOracle} from "src/adapter/redstone/RedstoneCoreArbitrumOracle.sol";

contract RedstoneCoreArbitrumOracleForkTest is ForkTest {
    RedstoneCoreArbitrumOracle oracle;

    function setUp() public {
        _setUpArbitrumForkLatest();
    }

    function test_UpdatePrice_WETH_USDC() public {
        oracle = new RedstoneCoreArbitrumOracle(WETH, USDC, REDSTONE_ETH_USD_FEED, 8, 3 minutes);
        (uint256 tsMillis, bytes memory payload) = _fetchRedstonePayload("ETH");
        bytes memory data = abi.encodePacked(abi.encodeCall(oracle.updatePrice, (uint48(tsMillis / 1000))), payload);

        (bool success,) = address(oracle).call(data);
        assertTrue(success);
        uint256 outAmount = oracle.getQuote(1e18, WETH, USDC);
        assertGt(outAmount, 0);
    }

    function test_UpdatePrice_ETHX_USD() public {
        oracle = new RedstoneCoreArbitrumOracle(ETHX, USD, REDSTONE_ETHX_USD_FEED, 8, 3 minutes);
        (uint256 tsMillis, bytes memory payload) = _fetchRedstonePayload("ETHx");
        bytes memory data = abi.encodePacked(abi.encodeCall(oracle.updatePrice, (uint48(tsMillis / 1000))), payload);

        (bool success,) = address(oracle).call(data);
        assertTrue(success);
        uint256 outAmount = oracle.getQuote(1e18, ETHX, USD);
        assertGt(outAmount, 100e18);
        assertLt(outAmount, 100000e18);
    }

    function test_UpdatePrice_RevertsWhen_WrongFeed() public {
        oracle = new RedstoneCoreArbitrumOracle(ETHX, USD, REDSTONE_ETHX_USD_FEED, 8, 3 minutes);
        (uint256 tsMillis, bytes memory payload) = _fetchRedstonePayload("BTC");
        bytes memory data = abi.encodePacked(abi.encodeCall(oracle.updatePrice, (uint48(tsMillis / 1000))), payload);

        (bool success,) = address(oracle).call(data);
        assertFalse(success);
    }

    function _fetchRedstonePayload(string memory feedSymbol)
        internal
        returns (uint256 tsMillis, bytes memory payload)
    {
        string[] memory cmds = new string[](3);
        cmds[0] = "node";
        cmds[1] = "test/adapter/redstone/RedstoneCoreArbitrumOracle/get_redstone_payload.js";
        cmds[2] = feedSymbol;
        payload = vm.ffi(cmds);
        assembly {
            tsMillis := shr(208, mload(add(payload, 0x60)))
        }
    }
}
