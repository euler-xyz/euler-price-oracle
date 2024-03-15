// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {PYTH, PYTH_ETH_USD_FEED, PYTH_GUSD_USD_FEED, WETH, USDC, DAI, GUSD} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract PythOracleForkTest is ForkTest {
    PythOracle oracle;

    function setUp() public {
        _setUpFork(19000000);
    }

    function test_GetQuote_Integrity_WETH_USDC() public {
        oracle = new PythOracle(PYTH, WETH, USDC, PYTH_ETH_USD_FEED, 1000 days, false);
        uint256 outAmount = oracle.getQuote(1e18, WETH, USDC);
        assertApproxEqRel(outAmount, 2500e6, 0.1e18);
    }

    function test_GetQuote_Integrity_WETH_DAI() public {
        oracle = new PythOracle(PYTH, WETH, DAI, PYTH_ETH_USD_FEED, 1000 days, false);
        uint256 outAmount = oracle.getQuote(1e18, WETH, DAI);
        assertApproxEqRel(outAmount, 2500e18, 0.1e18);
    }

    function test_GetQuote_Integrity_USDC_WETH_inverse() public {
        oracle = new PythOracle(PYTH, USDC, WETH, PYTH_ETH_USD_FEED, 1000 days, true);
        uint256 outAmount = oracle.getQuote(2500e6, USDC, WETH);
        assertApproxEqRel(outAmount, 1e18, 0.1e18);
    }

    function test_GetQuote_Integrity_DAI_WETH() public {
        oracle = new PythOracle(PYTH, DAI, WETH, PYTH_ETH_USD_FEED, 1000 days, true);
        uint256 outAmount = oracle.getQuote(2500e18, DAI, WETH);
        assertApproxEqRel(outAmount, 1e18, 0.1e18);
    }

    function test_GetQuotes_Integrity_WETH_USDC() public {
        oracle = new PythOracle(PYTH, WETH, USDC, PYTH_ETH_USD_FEED, 1000 days, false);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(1e18, WETH, USDC);
        assertApproxEqRel(bidOutAmount, 2500e6, 0.1e18);
        assertApproxEqRel(askOutAmount, 2500e6, 0.1e18);
        assertEq(bidOutAmount, askOutAmount);
    }

    function test_GetQuotes_Integrity_WETH_DAI() public {
        oracle = new PythOracle(PYTH, WETH, DAI, PYTH_ETH_USD_FEED, 1000 days, false);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(1e18, WETH, DAI);
        assertApproxEqRel(bidOutAmount, 2500e18, 0.1e18);
        assertApproxEqRel(askOutAmount, 2500e18, 0.1e18);
        assertEq(bidOutAmount, askOutAmount);
    }

    function test_GetQuotes_Integrity_USDC_WETH_inverse() public {
        oracle = new PythOracle(PYTH, USDC, WETH, PYTH_ETH_USD_FEED, 1000 days, true);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(2500e6, USDC, WETH);
        assertApproxEqRel(bidOutAmount, 1e18, 0.1e18);
        assertApproxEqRel(askOutAmount, 1e18, 0.1e18);
        assertEq(bidOutAmount, askOutAmount);
    }

    function test_GetQuotes_Integrity_DAI_WETH() public {
        oracle = new PythOracle(PYTH, DAI, WETH, PYTH_ETH_USD_FEED, 1000 days, true);
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(2500e18, DAI, WETH);
        assertApproxEqRel(bidOutAmount, 1e18, 0.1e18);
        assertApproxEqRel(askOutAmount, 1e18, 0.1e18);
        assertEq(bidOutAmount, askOutAmount);
    }
}
