// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IWstEth} from "src/adapter/lido/IWstEth.sol";
import {WstEthOracle} from "src/adapter/lido/WstEthOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract WstEthOracleTest is Test {
    address internal constant GOVERNOR = makeAddr("GOVERNOR");
    address internal constant STETH = makeAddr("STETH");
    address internal constant WSTETH = makeAddr("WSTETH");

    WstEthOracle oracle;

    function setUp() public {
        oracle = new WstEthOracle(STETH, WSTETH);
        oracle.initialize(GOVERNOR);
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
        vm.mockCallRevert(WSTETH, abi.encodeWithSelector(IWstEth.tokensPerStEth.selector), "");

        vm.expectRevert();
        oracle.getQuote(inAmount, STETH, WSTETH);
    }

    function test_GetQuote_RevertsWhen_StEth_WstEth_RateZero(uint256 inAmount) public {
        vm.mockCall(WSTETH, abi.encodeWithSelector(IWstEth.tokensPerStEth.selector), abi.encode(0));

        vm.expectRevert(Errors.EOracle_NoAnswer.selector);
        oracle.getQuote(inAmount, STETH, WSTETH);
    }

    function test_GetQuote_RevertsWhen_WstEth_StEth_WstEthCallReverts(uint256 inAmount) public {
        vm.mockCallRevert(WSTETH, abi.encodeWithSelector(IWstEth.stEthPerToken.selector), "");

        vm.expectRevert();
        oracle.getQuote(inAmount, WSTETH, STETH);
    }

    function test_GetQuote_RevertsWhen_WstEth_StEth_RateZero(uint256 inAmount) public {
        vm.mockCall(WSTETH, abi.encodeWithSelector(IWstEth.stEthPerToken.selector), abi.encode(0));

        vm.expectRevert(Errors.EOracle_NoAnswer.selector);
        oracle.getQuote(inAmount, WSTETH, STETH);
    }

    function test_GetQuote_StEth_WstEth_Integrity(uint256 inAmount, uint256 rate) public {
        inAmount = bound(inAmount, 1, type(uint128).max);
        rate = bound(rate, 1, type(uint128).max);
        uint256 expectedOutAmount = (inAmount * rate) / 1e18;
        vm.assume(expectedOutAmount != 0);

        vm.mockCall(WSTETH, abi.encodeWithSelector(IWstEth.tokensPerStEth.selector), abi.encode(rate));

        uint256 outAmount = oracle.getQuote(inAmount, STETH, WSTETH);
        assertEq(outAmount, expectedOutAmount);
    }

    function test_GetQuote_WstEth_SttEth_Integrity(uint256 inAmount, uint256 rate) public {
        inAmount = bound(inAmount, 1, type(uint128).max);
        rate = bound(rate, 1, type(uint128).max);
        uint256 expectedOutAmount = (inAmount * rate) / 1e18;
        vm.assume(expectedOutAmount != 0);

        vm.mockCall(WSTETH, abi.encodeWithSelector(IWstEth.stEthPerToken.selector), abi.encode(rate));

        uint256 outAmount = oracle.getQuote(inAmount, WSTETH, STETH);
        assertEq(outAmount, expectedOutAmount);
    }
}
