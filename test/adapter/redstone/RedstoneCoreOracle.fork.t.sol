// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {REDSTONE_ETH_USD_FEED} from "test/adapter/redstone/RedstoneFeeds.sol";
import {WETH, USDC, DAI, GUSD} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";

contract RedstoneCoreOracleForkTest is ForkTest {
    RedstoneCoreOracle oracle;

    function setUp() public {
        _setUpFork(19000000);
    }

    function test_GetQuote_Integrity_WETH_USDC() public {
        vm.skip(true);
        oracle = new RedstoneCoreOracle(WETH, USDC, REDSTONE_ETH_USD_FEED, 8, 3 minutes, 1 minutes);

        bytes memory getQuoteData = abi.encodeCall(oracle.getQuote, (1e18, WETH, USDC));
        bytes memory redstonePayload = abi.encode(1);
        bytes memory data = abi.encodePacked(getQuoteData, redstonePayload);

        (bool success,) = address(oracle).call(data);
        assertTrue(success);
        uint256 outAmount = oracle.getQuote(1e18, WETH, USDC);
        assertApproxEqRel(outAmount, 2500e6, 0.1e18);
    }
}
