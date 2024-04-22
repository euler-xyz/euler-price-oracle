// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {DAI, SDAI, DSR_POT} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {SDaiOracle} from "src/adapter/maker/SDaiOracle.sol";

contract SDaiOracleForkTest is ForkTest {
    SDaiOracle oracle;

    function setUp() public {
        _setUpFork(19000000);
        oracle = new SDaiOracle();
    }

    function test_GetQuote_Integrity() public view {
        uint256 sDaiDai = oracle.getQuote(1000e6, SDAI, DAI);
        assertApproxEqRel(sDaiDai, 1050e6, 0.1e18);

        uint256 daiSDai = oracle.getQuote(1000e6, DAI, SDAI);
        assertApproxEqRel(daiSDai, 950e6, 0.1e18);
    }

    function test_GetQuote_Integrity_EquivalentToDrip() public {
        uint256 sDaiDaiBeforeDrip = oracle.getQuote(1000e6, SDAI, DAI);
        uint256 daiSDaiBeforeDrip = oracle.getQuote(1000e6, DAI, SDAI);
        (bool success,) = DSR_POT.call(abi.encodeWithSelector(bytes4(keccak256("drip()"))));
        assertTrue(success);

        uint256 sDaiDaiAfterDrip = oracle.getQuote(1000e6, SDAI, DAI);
        uint256 daiSDaiAfterDrip = oracle.getQuote(1000e6, DAI, SDAI);
        assertEq(sDaiDaiBeforeDrip, sDaiDaiAfterDrip);
        assertEq(daiSDaiBeforeDrip, daiSDaiAfterDrip);
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
        (uint256 sDaiDaiBidBeforeDrip, uint256 sDaiDaiAskBeforeDrip) = oracle.getQuotes(1000e6, SDAI, DAI);
        (uint256 daiSDaiBidBeforeDrip, uint256 daiSDaiAskBeforeDrip) = oracle.getQuotes(1000e6, DAI, SDAI);
        (bool success,) = DSR_POT.call(abi.encodeWithSelector(bytes4(keccak256("drip()"))));
        assertTrue(success);

        (uint256 sDaiDaiBidAfterDrip, uint256 sDaiDaiAskAfterDrip) = oracle.getQuotes(1000e6, SDAI, DAI);
        (uint256 daiSDaiBidAfterDrip, uint256 daiSDaiAskAfterDrip) = oracle.getQuotes(1000e6, DAI, SDAI);
        assertEq(sDaiDaiBidBeforeDrip, sDaiDaiBidAfterDrip);
        assertEq(sDaiDaiAskBeforeDrip, sDaiDaiAskAfterDrip);
        assertEq(daiSDaiBidBeforeDrip, daiSDaiBidAfterDrip);
        assertEq(daiSDaiAskBeforeDrip, daiSDaiAskAfterDrip);
    }
}
