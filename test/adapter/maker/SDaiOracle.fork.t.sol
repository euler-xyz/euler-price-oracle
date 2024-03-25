// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {DAI, SDAI, DSR_POT} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {SDaiOracle} from "src/adapter/maker/SDaiOracle.sol";

contract SDaiOracleForkTest is ForkTest {
    SDaiOracle oracle;

    function setUp() public {
        _setUpFork(19000000);
        oracle = new SDaiOracle(DAI, SDAI, DSR_POT);
    }

    function test_GetQuote_Integrity() public view {
        uint256 sDaiDai = oracle.getQuote(1000e6, SDAI, DAI);
        assertApproxEqRel(sDaiDai, 1050e6, 0.1e18);

        uint256 daiSDai = oracle.getQuote(1000e6, DAI, SDAI);
        assertApproxEqRel(daiSDai, 950e6, 0.1e18);
    }

    function test_GetQuotes_Integrity() public view {
        (uint256 sDaiDaiBid, uint256 sDaiDaiAsk) = oracle.getQuotes(1000e6, SDAI, DAI);
        assertApproxEqRel(sDaiDaiBid, 1050e6, 0.1e18);
        assertApproxEqRel(sDaiDaiAsk, 1050e6, 0.1e18);

        (uint256 daiSDaiBid, uint256 daiSDaiAsk) = oracle.getQuotes(1000e6, DAI, SDAI);
        assertApproxEqRel(daiSDaiBid, 950e6, 0.1e18);
        assertApproxEqRel(daiSDaiAsk, 950e6, 0.1e18);
    }
}
