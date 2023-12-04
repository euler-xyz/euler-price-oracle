// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";
import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PYTH, PYTH_ETH_USD_FEED, PYTH_USDC_USD_FEED, USDC, WETH} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {ImmutablePythOracle} from "src/adapter/pyth/ImmutablePythOracle.sol";

contract ImmutablePythOracleForkTest is ForkTest {
    ImmutablePythOracle oracle;

    function setUp() public {
        _setUpFork();

        address[] memory tokens = new address[](2);
        tokens[0] = USDC;
        tokens[1] = WETH;

        bytes32[] memory feedIds = new bytes32[](2);
        feedIds[0] = PYTH_USDC_USD_FEED;
        feedIds[1] = PYTH_ETH_USD_FEED;

        oracle = new ImmutablePythOracle(PYTH);
        oracle.initialize(address(this), abi.encode(10000 days, tokens, feedIds));
    }

    function test_GetQuote() public {
        uint256 wethUsdc = oracle.getQuote(1 ether, WETH, USDC);
        assertGt(wethUsdc, 1e6 * 100, "1 ETH > 100 USDC");
        assertLt(wethUsdc, 1e6 * 10000, "1 ETH < 10000 USDC");

        uint256 usdcWeth = oracle.getQuote(1e6, USDC, WETH);
        assertGt(usdcWeth, 1e18 / 10000, "1 USDC > 0.0001 ETH");
        assertLt(usdcWeth, 1e18 / 100, "1 USDC < 0.01 ETH");
    }

    function test_GetQuotes() public {
        (uint256 wethUsdcBid, uint256 wethUsdcAsk) = oracle.getQuotes(1 ether, WETH, USDC);
        assertLt(wethUsdcBid, wethUsdcAsk);

        assertGt(wethUsdcAsk, 1e6 * 100, "1 ETH > 100 USDC");
        assertLt(wethUsdcAsk, 1e6 * 10000, "1 ETH < 10000 USDC");
        assertGt(wethUsdcBid, 1e6 * 100, "1 ETH > 100 USDC");
        assertLt(wethUsdcBid, 1e6 * 10000, "1 ETH < 10000 USDC");
    }
}
