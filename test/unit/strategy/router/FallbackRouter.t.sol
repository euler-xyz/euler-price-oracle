// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {FallbackRouter} from "src/strategy/router/FallbackRouter.sol";

contract FallbackRouterTest is Test {
    address internal GOVERNOR = makeAddr("GOVERNOR");
    address internal INITIAL_FALLBACK_ORACLE = makeAddr("INITIAL_FALLBACK_ORACLE");
    FallbackRouter private router;

    function setUp() public {
        router = new FallbackRouter(INITIAL_FALLBACK_ORACLE);
        router.initialize(GOVERNOR);
    }

    function test_Constructor_Integrity() public {
        assertEq(router.fallbackOracle(), INITIAL_FALLBACK_ORACLE);
    }

    function test_GovSetConfig_Integrity(address base, address quote, address oracle) public {
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracle);

        assertEq(router.oracles(base, quote), oracle);
    }

    function test_GovSetConfig_Integrity_OverwriteOk(address base, address quote, address oracleA, address oracleB)
        public
    {
        vm.expectEmit();
        emit FallbackRouter.ConfigSet(base, quote, oracleA);
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracleA);

        vm.expectEmit();
        emit FallbackRouter.ConfigSet(base, quote, oracleB);
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracleB);

        assertEq(router.oracles(base, quote), oracleB);
    }

    function test_GovSetConfig_RevertsWhen_CallerNotGovernor(
        address caller,
        address base,
        address quote,
        address oracle
    ) public {
        vm.assume(caller != GOVERNOR);

        vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
        router.govSetConfig(base, quote, oracle);
    }

    function test_GovUnsetConfig_Integrity(address base, address quote, address oracle) public {
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracle);

        vm.expectEmit();
        emit FallbackRouter.ConfigSet(base, quote, address(0));
        vm.prank(GOVERNOR);
        router.govUnsetConfig(base, quote);

        assertEq(router.oracles(base, quote), address(0));
    }

    function test_GovUnsetConfig_NoConfigOk(address base, address quote) public {
        vm.prank(GOVERNOR);
        router.govUnsetConfig(base, quote);

        assertEq(router.oracles(base, quote), address(0));
    }

    function test_GovUnsetConfig_RevertsWhen_CallerNotGovernor(address caller, address base, address quote) public {
        vm.assume(caller != GOVERNOR);

        vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
        router.govUnsetConfig(base, quote);
    }

    function test_GovSetFallbackOracle_Integrity(address fallbackOracle) public {
        vm.prank(GOVERNOR);
        router.govSetFallbackOracle(fallbackOracle);

        assertEq(router.fallbackOracle(), fallbackOracle);
    }

    function test_GovSetFallbackOracle_OverwriteOk(address fallbackOracleA, address fallbackOracleB) public {
        vm.prank(GOVERNOR);
        router.govSetFallbackOracle(fallbackOracleA);

        vm.prank(GOVERNOR);
        router.govSetFallbackOracle(fallbackOracleB);

        assertEq(router.fallbackOracle(), fallbackOracleB);
    }

    function test_GovSetFallbackOracle_ZeroOk() public {
        vm.prank(GOVERNOR);
        router.govSetFallbackOracle(address(0));

        assertEq(router.fallbackOracle(), address(0));
    }

    function test_GovSetFallbackOracle_RevertsWhen_CallerNotGovernor(address caller, address fallbackOracle) public {
        vm.assume(caller != GOVERNOR);

        vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
        router.govSetFallbackOracle(fallbackOracle);
    }

    function test_GetQuote_Integrity_HasConfig(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        uint256 outAmount
    ) public {
        oracle = boundAddr(oracle);
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracle);

        vm.mockCall(oracle, abi.encodeWithSelector(IEOracle.getQuote.selector), abi.encode(outAmount));
        uint256 actualOutAmount = router.getQuote(inAmount, base, quote);
        assertEq(actualOutAmount, outAmount);
    }

    function test_GetQuote_Integrity_NoConfigButHasFallback(
        uint256 inAmount,
        address base,
        address quote,
        uint256 outAmount
    ) public {
        vm.mockCall(INITIAL_FALLBACK_ORACLE, abi.encodeWithSelector(IEOracle.getQuote.selector), abi.encode(outAmount));
        uint256 actualOutAmount = router.getQuote(inAmount, base, quote);
        assertEq(actualOutAmount, outAmount);
    }

    function test_GetQuote_RevertsWhen_NoConfigAndNoFallback(uint256 inAmount, address base, address quote) public {
        vm.prank(GOVERNOR);
        router.govSetFallbackOracle(address(0));

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        router.getQuote(inAmount, base, quote);
    }

    function test_GetQuotes_Integrity_HasConfig(
        address oracle,
        uint256 inAmount,
        address base,
        address quote,
        uint256 bid,
        uint256 ask
    ) public {
        oracle = boundAddr(oracle);
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracle);

        vm.mockCall(oracle, abi.encodeWithSelector(IEOracle.getQuotes.selector), abi.encode(bid, ask));
        (uint256 actualBid, uint256 actualAsk) = router.getQuotes(inAmount, base, quote);
        assertEq(actualBid, bid);
        assertEq(actualAsk, ask);
    }

    function test_GetQuotes_Integrity_NoConfigButHasFallback(
        uint256 inAmount,
        address base,
        address quote,
        uint256 bid,
        uint256 ask
    ) public {
        vm.mockCall(INITIAL_FALLBACK_ORACLE, abi.encodeWithSelector(IEOracle.getQuotes.selector), abi.encode(bid, ask));
        (uint256 actualBid, uint256 actualAsk) = router.getQuotes(inAmount, base, quote);
        assertEq(actualBid, bid);
        assertEq(actualAsk, ask);
    }

    function test_GetQuotes_RevertsWhen_NoConfigAndNoFallback(uint256 inAmount, address base, address quote) public {
        vm.prank(GOVERNOR);
        router.govSetFallbackOracle(address(0));

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        router.getQuotes(inAmount, base, quote);
    }

    function test_Description() public {
        OracleDescription.Description memory desc = router.description();
        assertEq(uint8(desc.algorithm), uint8(OracleDescription.Algorithm.UNKNOWN));
        assertEq(uint8(desc.authority), uint8(OracleDescription.Authority.GOVERNED));
        assertEq(uint8(desc.paymentModel), uint8(OracleDescription.PaymentModel.UNKNOWN));
        assertEq(uint8(desc.requestModel), uint8(OracleDescription.RequestModel.INTERNAL));
        assertEq(uint8(desc.variant), uint8(OracleDescription.Variant.STRATEGY));
        assertEq(desc.configuration.maxStaleness, 0);
        assertEq(desc.configuration.governor, GOVERNOR);
        assertEq(desc.configuration.supportsBidAskSpread, false);
    }

    function test_TransferGovernance_RevertsWhen_CallerNotGovernor(address caller, address newGovernor) public {
        vm.assume(caller != GOVERNOR);
        vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
        vm.prank(caller);
        router.transferGovernance(newGovernor);
    }

    function test_TransferGovernance_Integrity(address newGovernor) public {
        vm.assume(newGovernor != address(0));
        vm.prank(GOVERNOR);
        router.transferGovernance(newGovernor);

        assertEq(router.governor(), newGovernor);
        assertTrue(router.governed());
        assertFalse(router.finalized());
    }

    function test_TransferGovernance_Integrity_ZeroAddress() public {
        vm.prank(GOVERNOR);
        router.transferGovernance(address(0));

        assertEq(router.governor(), address(0));
        assertFalse(router.governed());
        assertTrue(router.finalized());
    }

    function test_RenounceGovernance_RevertsWhen_CallerNotGovernor(address caller) public {
        vm.assume(caller != GOVERNOR);
        vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
        vm.prank(caller);
        router.renounceGovernance();
    }

    function test_RenounceGovernance_Integrity() public {
        vm.prank(GOVERNOR);
        router.renounceGovernance();

        assertEq(router.governor(), address(0));
        assertFalse(router.governed());
        assertTrue(router.finalized());
    }
}
