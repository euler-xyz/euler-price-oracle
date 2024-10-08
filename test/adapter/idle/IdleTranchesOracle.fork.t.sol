// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {
    IDLE_CDO_FASANARA_USDC,
    IDLE_TRANCHE_FASANARA_USDC_AA,
    IDLE_TRANCHE_FASANARA_USDC_BB,
    IDLE_CDO_STEAKHOUSE_USDC,
    IDLE_TRANCHE_STEAKHOUSE_USDC_AA,
    IDLE_TRANCHE_STEAKHOUSE_USDC_BB,
    IDLE_CDO_LIDO_STETH,
    IDLE_TRANCHE_LIDO_STETH_AA,
    IDLE_TRANCHE_LIDO_STETH_BB
} from "test/adapter/idle/IdleAddresses.sol";
import {STETH, USDC} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {IdleTranchesOracle} from "src/adapter/idle/IdleTranchesOracle.sol";

contract IdleTranchesOracleForkTest is ForkTest {
    function setUp() public {
        _setUpFork(20865374);
    }

    function test_Constructor_Integrity() public {
        IdleTranchesOracle oracle = new IdleTranchesOracle(IDLE_CDO_FASANARA_USDC, IDLE_TRANCHE_FASANARA_USDC_AA);
        assertEq(oracle.cdo(), IDLE_CDO_FASANARA_USDC);
        assertEq(oracle.tranche(), IDLE_TRANCHE_FASANARA_USDC_AA);
        assertEq(oracle.underlying(), USDC);
    }

    function test_GetQuote_Integrity_Fasanara_USDC_AA() public {
        IdleTranchesOracle oracle = new IdleTranchesOracle(IDLE_CDO_FASANARA_USDC, IDLE_TRANCHE_FASANARA_USDC_AA);

        uint256 outAmount = oracle.getQuote(1e18, IDLE_TRANCHE_FASANARA_USDC_AA, USDC);
        uint256 outAmount1000 = oracle.getQuote(1000e18, IDLE_TRANCHE_FASANARA_USDC_AA, USDC);
        assertEq(outAmount, 1.000344e6);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDC, IDLE_TRANCHE_FASANARA_USDC_AA);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USDC, IDLE_TRANCHE_FASANARA_USDC_AA);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_Integrity_Fasanara_USDC_BB() public {
        IdleTranchesOracle oracle = new IdleTranchesOracle(IDLE_CDO_FASANARA_USDC, IDLE_TRANCHE_FASANARA_USDC_BB);

        uint256 outAmount = oracle.getQuote(1e18, IDLE_TRANCHE_FASANARA_USDC_BB, USDC);
        uint256 outAmount1000 = oracle.getQuote(1000e18, IDLE_TRANCHE_FASANARA_USDC_BB, USDC);
        assertEq(outAmount, 1e6);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDC, IDLE_TRANCHE_FASANARA_USDC_BB);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USDC, IDLE_TRANCHE_FASANARA_USDC_BB);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_Integrity_Steakhouse_USDC_AA() public {
        IdleTranchesOracle oracle = new IdleTranchesOracle(IDLE_CDO_STEAKHOUSE_USDC, IDLE_TRANCHE_STEAKHOUSE_USDC_AA);

        uint256 outAmount = oracle.getQuote(1e18, IDLE_TRANCHE_STEAKHOUSE_USDC_AA, USDC);
        uint256 outAmount1000 = oracle.getQuote(1000e18, IDLE_TRANCHE_STEAKHOUSE_USDC_AA, USDC);
        assertEq(outAmount, 1.043299e6);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDC, IDLE_TRANCHE_STEAKHOUSE_USDC_AA);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USDC, IDLE_TRANCHE_STEAKHOUSE_USDC_AA);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_Integrity_Steakhouse_USDC_BB() public {
        IdleTranchesOracle oracle = new IdleTranchesOracle(IDLE_CDO_STEAKHOUSE_USDC, IDLE_TRANCHE_STEAKHOUSE_USDC_BB);

        uint256 outAmount = oracle.getQuote(1e18, IDLE_TRANCHE_STEAKHOUSE_USDC_BB, USDC);
        uint256 outAmount1000 = oracle.getQuote(1000e18, IDLE_TRANCHE_STEAKHOUSE_USDC_BB, USDC);
        assertEq(outAmount, 1.099605e6);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDC, IDLE_TRANCHE_STEAKHOUSE_USDC_BB);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USDC, IDLE_TRANCHE_STEAKHOUSE_USDC_BB);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_Integrity_Lido_STETH_AA() public {
        IdleTranchesOracle oracle = new IdleTranchesOracle(IDLE_CDO_LIDO_STETH, IDLE_TRANCHE_LIDO_STETH_AA);

        uint256 outAmount = oracle.getQuote(1e18, IDLE_TRANCHE_LIDO_STETH_AA, STETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, IDLE_TRANCHE_LIDO_STETH_AA, STETH);
        assertEq(outAmount, 1.075301441677891991e18);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, STETH, IDLE_TRANCHE_LIDO_STETH_AA);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, STETH, IDLE_TRANCHE_LIDO_STETH_AA);
        assertEq(outAmountInv1000, 1000e18);
    }

    function test_GetQuote_Integrity_Lido_STETH_BB() public {
        IdleTranchesOracle oracle = new IdleTranchesOracle(IDLE_CDO_LIDO_STETH, IDLE_TRANCHE_LIDO_STETH_BB);

        uint256 outAmount = oracle.getQuote(1e18, IDLE_TRANCHE_LIDO_STETH_BB, STETH);
        uint256 outAmount1000 = oracle.getQuote(1000e18, IDLE_TRANCHE_LIDO_STETH_BB, STETH);
        assertEq(outAmount, 1.20260636086349279e18);
        assertEq(outAmount1000, outAmount * 1000);

        uint256 outAmountInv = oracle.getQuote(outAmount, STETH, IDLE_TRANCHE_LIDO_STETH_BB);
        assertEq(outAmountInv, 1e18);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, STETH, IDLE_TRANCHE_LIDO_STETH_BB);
        assertEq(outAmountInv1000, 1000e18);
    }
}
