// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {DAI, SDAI, DSR_POT} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {IPot} from "src/adapter/maker/IPot.sol";
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

    function test_GetQuote_Integrity_EquivalentToDrip() public {
        (bool success,) = DSR_POT.call(abi.encodeWithSelector(bytes4(keccak256("drip()"))));
        assertTrue(success);

        uint256 chi = IPot(DSR_POT).chi();
        uint256 sDaiDai = oracle.getQuote(1000e6, SDAI, DAI);
        assertEq(sDaiDai, 1000e6 * chi / 1e27);

        uint256 daiSDai = oracle.getQuote(1000e6, DAI, SDAI);
        assertEq(daiSDai, 1000e6 * 1e27 / chi);
    }

    function test_GetQuotes_Integrity() public view {
        (uint256 sDaiDaiBid, uint256 sDaiDaiAsk) = oracle.getQuotes(1000e6, SDAI, DAI);
        assertApproxEqRel(sDaiDaiBid, 1050e6, 0.1e18);
        assertApproxEqRel(sDaiDaiAsk, 1050e6, 0.1e18);

        (uint256 daiSDaiBid, uint256 daiSDaiAsk) = oracle.getQuotes(1000e6, DAI, SDAI);
        assertApproxEqRel(daiSDaiBid, 950e6, 0.1e18);
        assertApproxEqRel(daiSDaiAsk, 950e6, 0.1e18);
    }

    function test_GetQuotes_Integrity_EquivalentToDrip() public {
        (bool success,) = DSR_POT.call(abi.encodeWithSelector(bytes4(keccak256("drip()"))));
        assertTrue(success);

        uint256 chi = IPot(DSR_POT).chi();

        (uint256 sDaiDaiBid, uint256 sDaiDaiAsk) = oracle.getQuotes(1000e6, SDAI, DAI);
        assertEq(sDaiDaiBid, 1000e6 * chi / 1e27);
        assertEq(sDaiDaiAsk, 1000e6 * chi / 1e27);

        (uint256 daiSDaiBid, uint256 daiSDaiAsk) = oracle.getQuotes(1000e6, DAI, SDAI);
        assertEq(daiSDaiBid, 1000e6 * 1e27 / chi);
        assertEq(daiSDaiAsk, 1000e6 * 1e27 / chi);
    }
}
