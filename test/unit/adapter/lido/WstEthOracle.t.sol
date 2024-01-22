// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IStEth} from "src/adapter/lido/IStEth.sol";
import {LidoOracle} from "src/adapter/lido/LidoOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract LidoOracleTest is Test {
    address internal STETH = makeAddr("STETH");
    address internal WSTETH = makeAddr("WSTETH");

    LidoOracle oracle;

    function setUp() public {
        oracle = new LidoOracle(STETH, WSTETH);
    }

    function test_GetQuote_RevertsWhen_InvalidBase_A(uint256 inAmount, address base) public {
        vm.assume(base != WSTETH);
        address quote = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_InvalidBase_B(uint256 inAmount, address base) public {
        vm.assume(base != STETH);
        address quote = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_InvalidQuote_A(uint256 inAmount, address quote) public {
        vm.assume(quote != WSTETH);
        address base = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_InvalidQuote_B(uint256 inAmount, address quote) public {
        vm.assume(quote != STETH);
        address base = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_SameTokens_StEth(uint256 inAmount) public {
        address base = STETH;
        address quote = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_SameTokens_WstEth(uint256 inAmount) public {
        address base = WSTETH;
        address quote = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_StEth_WstEth_WstEthCallReverts(uint256 inAmount) public {
        vm.mockCallRevert(STETH, abi.encodeWithSelector(IStEth.getSharesByPooledEth.selector), "");

        vm.expectRevert();
        oracle.getQuote(inAmount, STETH, WSTETH);
    }

    function test_GetQuote_RevertsWhen_WstEth_StEth_WstEthCallReverts(uint256 inAmount) public {
        vm.mockCallRevert(STETH, abi.encodeWithSelector(IStEth.getPooledEthByShares.selector), "");

        vm.expectRevert();
        oracle.getQuote(inAmount, WSTETH, STETH);
    }

    function test_GetQuote_StEth_WstEth_Integrity(uint256 inAmount, uint256 outAmount) public {
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(STETH, abi.encodeWithSelector(IStEth.getSharesByPooledEth.selector), abi.encode(outAmount));

        uint256 actualOutAmount = oracle.getQuote(inAmount, STETH, WSTETH);
        assertEq(actualOutAmount, outAmount);
    }

    function test_GetQuote_WstEth_StEth_Integrity(uint256 inAmount, uint256 outAmount) public {
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(STETH, abi.encodeWithSelector(IStEth.getPooledEthByShares.selector), abi.encode(outAmount));

        uint256 actualOutAmount = oracle.getQuote(inAmount, WSTETH, STETH);
        assertEq(actualOutAmount, outAmount);
    }

    function test_GetQuotes_RevertsWhen_InvalidBase_A(uint256 inAmount, address base) public {
        vm.assume(base != WSTETH);
        address quote = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidBase_B(uint256 inAmount, address base) public {
        vm.assume(base != STETH);
        address quote = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidQuote_A(uint256 inAmount, address quote) public {
        vm.assume(quote != WSTETH);
        address base = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_InvalidQuote_B(uint256 inAmount, address quote) public {
        vm.assume(quote != STETH);
        address base = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_SameTokens_StEth(uint256 inAmount) public {
        address base = STETH;
        address quote = STETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_SameTokens_WstEth(uint256 inAmount) public {
        address base = WSTETH;
        address quote = WSTETH;

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_RevertsWhen_StEth_WstEth_WstEthCallReverts(uint256 inAmount) public {
        vm.mockCallRevert(STETH, abi.encodeWithSelector(IStEth.getSharesByPooledEth.selector), "");

        vm.expectRevert();
        oracle.getQuote(inAmount, STETH, WSTETH);
    }

    function test_GetQuotes_RevertsWhen_WstEth_StEth_WstEthCallReverts(uint256 inAmount) public {
        vm.mockCallRevert(STETH, abi.encodeWithSelector(IStEth.getPooledEthByShares.selector), "");

        vm.expectRevert();
        oracle.getQuotes(inAmount, WSTETH, STETH);
    }

    function test_GetQuotes_StEth_WstEth_Integrity(uint256 inAmount, uint256 outAmount) public {
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(STETH, abi.encodeWithSelector(IStEth.getSharesByPooledEth.selector), abi.encode(outAmount));

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, STETH, WSTETH);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
    }

    function test_GetQuotes_WstEth_StEth_Integrity(uint256 inAmount, uint256 outAmount) public {
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(STETH, abi.encodeWithSelector(IStEth.getPooledEthByShares.selector), abi.encode(outAmount));

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, WSTETH, STETH);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
    }

    function test_Description() public {
        OracleDescription.Description memory desc = oracle.description();
        assertEq(uint8(desc.algorithm), uint8(OracleDescription.Algorithm.SPOT));
        assertEq(uint8(desc.authority), uint8(OracleDescription.Authority.IMMUTABLE));
        assertEq(uint8(desc.paymentModel), uint8(OracleDescription.PaymentModel.FREE));
        assertEq(uint8(desc.requestModel), uint8(OracleDescription.RequestModel.PUSH));
        assertEq(uint8(desc.variant), uint8(OracleDescription.Variant.ADAPTER));
        assertEq(desc.configuration.maxStaleness, 0);
        assertEq(desc.configuration.governor, address(0));
        assertEq(desc.configuration.supportsBidAskSpread, false);
    }
}
