// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import "test/utils/EthereumAddresses.sol";
import {WbtcOracle} from "src/wbtc/WbtcOracle.sol";

contract WbtcOracleForkTest is Test {
    uint256 constant ETHEREUM_FORK_BLOCK = 18515555;
    uint256 ethereumFork;
    WbtcOracle oracle;

    function setUp() public {
        string memory ETHEREUM_RPC_URL = vm.envString("ETHEREUM_RPC_URL");
        ethereumFork = vm.createFork(ETHEREUM_RPC_URL);
        vm.selectFork(ethereumFork);
        vm.roll(ETHEREUM_FORK_BLOCK);

        oracle = new WbtcOracle(WETH, WBTC, WBTC_BTC_FEED, BTC_ETH_FEED, FEED_REGISTRY);
    }

    function test_GetQuote() public {
        uint256 quoteUnit = oracle.getQuote(1e8, WBTC, WETH);
        assertGt(quoteUnit, 10 ether, "1 BTC > 10 WETH");
        assertLt(quoteUnit, 100 ether, "1 BTC < 100 WETH");

        uint256 quoteBig = oracle.getQuote(1000e8, WBTC, WETH);
        assertGt(quoteBig, 10000 ether, "1000 BTC > 10 WETH");
        assertLt(quoteBig, 100000 ether, "1000 BTC < 100000 WETH");

        uint256 quoteSmall = oracle.getQuote(1, WBTC, WETH);
        assertGt(quoteSmall, 1e11, "1 sat > 1e-7 WETH");
        assertLt(quoteSmall, 1e10, "1 sat < 1e-8 WETH");

        uint256 invQuoteUnit = oracle.getQuote(1 ether, WETH, WBTC);
        assertGt(invQuoteUnit, 0.01e8, "1 WETH > 0.01 BTC");
        assertLt(invQuoteUnit, 0.1e8, "1 WETH < 0.1 BTC");

        uint256 invQuoteBig = oracle.getQuote(1000 ether, WETH, WBTC);
        assertGt(invQuoteBig, 10e8, "1000 WETH > 10 BTC");
        assertLt(invQuoteBig, 100e8, "1000 WETH < 100 BTC");

        uint256 invQuoteSmall = oracle.getQuote(1e3, WETH, WBTC);
        assertGt(invQuoteSmall, 10, "1e-6 WETH > 10 sat");
        assertLt(invQuoteSmall, 100, "1e-6 WETH < 100 sat");
    }
}
