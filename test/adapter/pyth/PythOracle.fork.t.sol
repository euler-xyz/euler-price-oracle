// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PYTH, PYTH_ETH_USD_FEED, PYTH_USDC_USD_FEED, USDC, WETH} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";
import {BasePythOracle} from "src/adapter/pyth/BasePythOracle.sol";

contract PythOracleForkTest is ForkTest {
    PythOracle oracle;

    function setUp() public {
        _setUpFork();

        BasePythOracle.ConfigParams[] memory initialConfigs = new BasePythOracle.ConfigParams[](2);
        initialConfigs[0] = BasePythOracle.ConfigParams(PYTH_USDC_USD_FEED, USDC);
        initialConfigs[1] = BasePythOracle.ConfigParams(PYTH_ETH_USD_FEED, WETH);

        oracle = new PythOracle(PYTH, 10000 days, initialConfigs);
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
