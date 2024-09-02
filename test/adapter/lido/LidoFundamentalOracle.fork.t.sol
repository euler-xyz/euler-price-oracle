// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {WETH, WSTETH} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {LidoFundamentalOracle} from "src/adapter/lido/LidoFundamentalOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract LidoFundamentalOracleForkTest is ForkTest {
    LidoFundamentalOracle oracle;

    function setUp() public {
        _setUpFork(19000000);
        oracle = new LidoFundamentalOracle();
    }

    function test_GetQuote_Integrity() public view {
        uint256 stEthWstEth = oracle.getQuote(1e18, WETH, WSTETH);
        assertApproxEqRel(stEthWstEth, 0.85e18, 0.1e18);

        uint256 wstEthStEth = oracle.getQuote(1e18, WSTETH, WETH);
        assertApproxEqRel(wstEthStEth, 1.15e18, 0.1e18);
    }

    function test_GetQuotes_Integrity() public view {
        (uint256 stEthWstEthBid, uint256 stEthWstEthAsk) = oracle.getQuotes(1e18, WETH, WSTETH);
        assertApproxEqRel(stEthWstEthBid, 0.85e18, 0.1e18);
        assertApproxEqRel(stEthWstEthAsk, 0.85e18, 0.1e18);

        (uint256 wstEthStEthBid, uint256 wstEthStEthAsk) = oracle.getQuotes(1e18, WSTETH, WETH);
        assertApproxEqRel(wstEthStEthBid, 1.15e18, 0.1e18);
        assertApproxEqRel(wstEthStEthAsk, 1.15e18, 0.1e18);
    }
}
