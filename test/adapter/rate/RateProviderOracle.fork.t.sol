// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {
    BALANCER_WSTETH_RATE_PROVIDER,
    BALANCER_RETH_RATE_PROVIDER,
    BALANCER_EZETH_RATE_PROVIDER,
    BALANCER_WEETH_RATE_PROVIDER,
    BALANCER_RSETH_RATE_PROVIDER,
    BALANCER_UNIETH_RATE_PROVIDER,
    BALANCER_SDAI_RATE_PROVIDER,
    BALANCER_SUSDE_RATE_PROVIDER,
    BALANCER_SDOLA_RATE_PROVIDER,
    BALANCER_XAUT_RATE_PROVIDER
} from "test/adapter/rate/RateProviderAddresses.sol";
import {
    WSTETH,
    RETH,
    EZETH,
    WEETH,
    RSETH,
    UNIETH,
    SDAI,
    SUSDE,
    SDOLA,
    XAUT,
    WETH,
    USD
} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {RateProviderOracle} from "src/adapter/rate/RateProviderOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract RateProviderOracleForkTest is ForkTest {
    /// @dev 1%
    uint256 constant REL_PRECISION = 0.01e18;

    function setUp() public {
        _setUpFork(20569829);
    }

    function test_Constructor_Integrity() public {
        RateProviderOracle oracle = new RateProviderOracle(WSTETH, WETH, BALANCER_WSTETH_RATE_PROVIDER);
        assertEq(oracle.base(), WSTETH);
        assertEq(oracle.quote(), WETH);
        assertEq(oracle.rateProvider(), BALANCER_WSTETH_RATE_PROVIDER);
    }

    function test_GetQuote_wstETH() public {
        RateProviderOracle oracle = new RateProviderOracle(WSTETH, WETH, BALANCER_WSTETH_RATE_PROVIDER);

        uint256 outAmount = oracle.getQuote(1e18, WSTETH, WETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, WSTETH, WETH);
        assertApproxEqRel(outAmount, 1.1765e18, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, WETH, WSTETH);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, WETH, WSTETH);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_rETH() public {
        RateProviderOracle oracle = new RateProviderOracle(RETH, WETH, BALANCER_RETH_RATE_PROVIDER);
        uint256 rate = 1.1142e18;

        uint256 outAmount = oracle.getQuote(1e18, RETH, WETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, RETH, WETH);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, WETH, RETH);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, WETH, RETH);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_ezETH() public {
        RateProviderOracle oracle = new RateProviderOracle(EZETH, WETH, BALANCER_EZETH_RATE_PROVIDER);
        uint256 rate = 1.0172e18;

        uint256 outAmount = oracle.getQuote(1e18, EZETH, WETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, EZETH, WETH);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, WETH, EZETH);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, WETH, EZETH);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_weETH() public {
        RateProviderOracle oracle = new RateProviderOracle(WEETH, WETH, BALANCER_WEETH_RATE_PROVIDER);
        uint256 rate = 1.046e18;

        uint256 outAmount = oracle.getQuote(1e18, WEETH, WETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, WEETH, WETH);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, WETH, WEETH);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, WETH, WEETH);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_rsETH() public {
        RateProviderOracle oracle = new RateProviderOracle(RSETH, WETH, BALANCER_RSETH_RATE_PROVIDER);
        uint256 rate = 1.0215e18;

        uint256 outAmount = oracle.getQuote(1e18, RSETH, WETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, RSETH, WETH);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, WETH, RSETH);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, WETH, RSETH);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_uniETH() public {
        RateProviderOracle oracle = new RateProviderOracle(UNIETH, WETH, BALANCER_UNIETH_RATE_PROVIDER);
        uint256 rate = 1.0724e18;

        uint256 outAmount = oracle.getQuote(1e18, UNIETH, WETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, UNIETH, WETH);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, WETH, UNIETH);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, WETH, UNIETH);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_sDAI() public {
        RateProviderOracle oracle = new RateProviderOracle(SDAI, USD, BALANCER_EZETH_RATE_PROVIDER);
        uint256 rate = 1.0172e18;

        uint256 outAmount = oracle.getQuote(1e18, SDAI, USD);
        uint256 outAmount1000 = oracle.getQuote(1000e18, SDAI, USD);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USD, SDAI);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USD, SDAI);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_sUSDE() public {
        RateProviderOracle oracle = new RateProviderOracle(SUSDE, USD, BALANCER_SUSDE_RATE_PROVIDER);
        uint256 rate = 1.0975e18;

        uint256 outAmount = oracle.getQuote(1e18, SUSDE, USD);
        uint256 outAmount1000 = oracle.getQuote(1000e18, SUSDE, USD);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USD, SUSDE);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USD, SUSDE);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_sDOLA() public {
        RateProviderOracle oracle = new RateProviderOracle(SDOLA, USD, BALANCER_SDOLA_RATE_PROVIDER);
        uint256 rate = 1.0562e18;

        uint256 outAmount = oracle.getQuote(1e18, SDOLA, USD);
        uint256 outAmount1000 = oracle.getQuote(1000e18, SDOLA, USD);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USD, SDOLA);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USD, SDOLA);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_XAUT() public {
        RateProviderOracle oracle = new RateProviderOracle(XAUT, USD, BALANCER_XAUT_RATE_PROVIDER);
        uint256 rate = 2522e18;

        uint256 outAmount = oracle.getQuote(1e6, XAUT, USD);
        uint256 outAmount1000 = oracle.getQuote(1000e6, XAUT, USD);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USD, XAUT);
        assertEq(outAmountInv, 1e6);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USD, XAUT);
        assertEq(outAmountInv1000, 1000e6);
    }
}
