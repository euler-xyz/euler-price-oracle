// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {LDO, USDC, WETH} from "test/utils/EthereumAddresses.sol";
import {ImmutableChainlinkAdapter} from "src/chainlink/ImmutableChainlinkAdapter.sol";

contract ImmutableChainlinkAdapterForkTest is Test {
    address constant CHAINLINK_FEED_REGISTRY = 0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf;
    uint256 constant ETHEREUM_FORK_BLOCK = 18515500;
    uint256 ethereumFork;
    ImmutableChainlinkAdapter adapter;

    function setUp() public {
        string memory ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL");
        ethereumFork = vm.createFork(ETHEREUM_RPC_URL);
        vm.selectFork(ethereumFork);
        vm.roll(ETHEREUM_FORK_BLOCK);

        adapter = new ImmutableChainlinkAdapter(CHAINLINK_FEED_REGISTRY, WETH);
    }

    function test_GetQuote_SameDecimals() public {
        uint256 quote = adapter.getQuote(1 ether, LDO, WETH);
        assertGt(quote, 1e18 / 10000, "1 LDO > 0.0001 ETH");
        assertLt(quote, 1e18 / 100, "1 LDO < 0.01 ETH");

        uint256 quoteInv = adapter.getQuote(1 ether, WETH, LDO);
        assertGt(quoteInv, 1e18 * 100, "1 ETH > 100 LDO");
        assertLt(quoteInv, 1e18 * 10000, "1 ETH < 10000 LDO");

        uint256 unit = (quote * quoteInv) / 1e18;
        assertApproxEqRel(unit, 1e18, 0.01e18);
    }

    function test_GetQuote_DiffDecimals() public {
        uint256 quote = adapter.getQuote(1e6, USDC, WETH);
        assertGt(quote, 1e18 / 10000, "1 USDC > 0.0001 ETH");
        assertLt(quote, 1e18 / 100, "1 USDC < 0.01 ETH");

        uint256 quoteInv = adapter.getQuote(1 ether, WETH, USDC);
        assertGt(quoteInv, 1e6 * 100, "1 ETH > 100 USDC");
        assertLt(quoteInv, 1e6 * 10000, "1 ETH < 10000 USDC");

        uint256 unit = (quote * quoteInv) / 1e6;
        assertApproxEqRel(unit, 1e18, 0.01e18);
    }
}
