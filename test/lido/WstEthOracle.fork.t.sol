// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {FEED_REGISTRY, CHAINLINK_STETH_ETH_FEED, WETH, WSTETH} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {WstEthOracle} from "src/lido/WstEthOracle.sol";

contract WstEthOracleForkTest is ForkTest {
    WstEthOracle oracle;

    function setUp() public {
        _setUpFork();
        oracle = new WstEthOracle(WETH, WSTETH, CHAINLINK_STETH_ETH_FEED, FEED_REGISTRY);
    }

    function test_GetQuote() public {
        uint256 quoteUnit = oracle.getQuote(1 ether, WSTETH, WETH);
        assertGt(quoteUnit, 1 ether, "1 WstEth > 1 Weth");
        assertLt(quoteUnit, 1.2 ether, "1 WstEth < 1.2 Weth");

        uint256 quoteBig = oracle.getQuote(1000 ether, WSTETH, WETH);
        assertGt(quoteBig, 1000 ether, "1000 WstEth > 1000 Weth");
        assertLt(quoteBig, 1200 ether, "1000 WstEth < 1200 Weth");

        uint256 quoteSmall = oracle.getQuote(1e3, WSTETH, WETH);
        assertGt(quoteSmall, 1e3, "1e-15 WstEth > 1e-15 Weth");
        assertLt(quoteSmall, 1.2e3 ether, "1e-15 WstEth < 1.2e-15 Weth");

        uint256 invQuoteUnit = oracle.getQuote(1 ether, WETH, WSTETH);
        assertGt(invQuoteUnit, 0.8 ether, "1 Weth > 0.8 WstEth");
        assertLt(invQuoteUnit, 1 ether, "1 Weth < 1 WstEth");

        uint256 invQuoteBig = oracle.getQuote(1000 ether, WETH, WSTETH);
        assertGt(invQuoteBig, 800 ether, "1000 Weth > 800 WstEth");
        assertLt(invQuoteBig, 1000 ether, "1000 Weth < 1000 WstEth");

        uint256 invQuoteSmall = oracle.getQuote(1e3, WETH, WSTETH);
        assertGt(invQuoteSmall, 0.8e3, "1e-15 Weth > 0.8e-15 WstEth");
        assertLt(invQuoteSmall, 1e3, "1e-15 Weth < 1e-15 WstEth");
    }
}
