// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {SDAI, DAI, USDM, WUSDM, USDL, WUSDL} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {ERC4626Oracle} from "src/adapter/erc4626/ERC4626Oracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract ERC4626OracleForkTest is ForkTest {
    uint256 constant ABS_PRECISION = 1;
    uint256 constant REL_PRECISION = 0.000001e18;

    function setUp() public {
        _setUpFork();
        vm.rollFork(21967153);
    }

    function test_Constructor_Integrity() public {
        ERC4626Oracle oracle = new ERC4626Oracle(SDAI);
        assertEq(oracle.base(), SDAI);
        assertEq(oracle.quote(), DAI);
    }

    function test_GetQuote_SDAI() public {
        uint256 rate = 1.1493126e18;
        ERC4626Oracle oracle = new ERC4626Oracle(SDAI);

        uint256 outAmount = oracle.getQuote(1e18, SDAI, DAI);
        uint256 outAmount1000 = oracle.getQuote(1000e18, SDAI, DAI);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertApproxEqRel(outAmount1000, rate * 1000, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, DAI, SDAI);
        assertApproxEqAbs(outAmountInv, 1e18, ABS_PRECISION);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, DAI, SDAI);
        assertApproxEqAbs(outAmountInv1000, 1000e18, ABS_PRECISION);
    }

    function test_GetQuote_WUSDM() public {
        uint256 rate = 1.070076852246772245e18;
        ERC4626Oracle oracle = new ERC4626Oracle(WUSDM);

        uint256 outAmount = oracle.getQuote(1e18, WUSDM, USDM);
        uint256 outAmount1000 = oracle.getQuote(1000e18, WUSDM, USDM);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertApproxEqRel(outAmount1000, rate * 1000, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDM, WUSDM);
        assertApproxEqAbs(outAmountInv, 1e18, ABS_PRECISION);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USDM, WUSDM);
        assertApproxEqAbs(outAmountInv1000, 1000e18, ABS_PRECISION);
    }

    function test_GetQuote_WUSDL() public {
        uint256 rate = 1.01639231015737408e18;
        ERC4626Oracle oracle = new ERC4626Oracle(WUSDL);

        uint256 outAmount = oracle.getQuote(1e18, WUSDL, USDL);
        uint256 outAmount1000 = oracle.getQuote(1000e18, WUSDL, USDL);
        assertApproxEqRel(outAmount, rate, REL_PRECISION);
        assertApproxEqRel(outAmount1000, rate * 1000, REL_PRECISION);

        uint256 outAmountInv = oracle.getQuote(outAmount, USDL, WUSDL);
        assertApproxEqAbs(outAmountInv, 1e18, ABS_PRECISION);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USDL, WUSDL);
        assertApproxEqAbs(outAmountInv1000, 1000e18, ABS_PRECISION);
    }
}
