// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {ERC4626} from "@solady/tokens/ERC4626.sol";
import {LibPRNG} from "@solady/utils/LibPRNG.sol";
import {EFactory} from "@euler-vault/EFactory/EFactory.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {AxiomRouter} from "src/strategy/router/AxiomRouter.sol";

contract StubERC4626 {
    address public asset;
    uint256 private rate;

    constructor(address _asset, uint256 _rate) {
        asset = _asset;
        rate = _rate;
    }

    function convertToAssets(uint256 shares) external view returns (uint256) {
        return shares * rate / 1e18;
    }

    function convertToShares(uint256 assets) external view returns (uint256) {
        return assets * 1e18 / rate;
    }
}

contract StubEOracle {
    mapping(address => mapping(address => uint256)) prices;

    function setPrice(address base, address quote, uint256 price) external {
        prices[base][quote] = price;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return inAmount * prices[base][quote] / 1e18;
    }
}

contract StubEFactory {
    mapping(address => bool) public isProxy;

    function setIsProxy(address x, bool y) public {
        isProxy[x] = y;
    }
}

contract AxiomRouterTest is Test {
    address GOVERNOR = makeAddr("GOVERNOR");
    StubEFactory eFactory;
    AxiomRouter router;

    address WETH = makeAddr("WETH");
    address eWETH;
    address eeWETH;

    address DAI = makeAddr("DAI");
    address eDAI;
    address eeDAI;

    StubEOracle eOracle;

    function setUp() public {
        eFactory = new StubEFactory();
        router = new AxiomRouter(address(eFactory));
        router.initialize(GOVERNOR);
    }

    function test_Constructor_Integrity(address _eFactory) public {
        AxiomRouter _router = new AxiomRouter(_eFactory);
        assertEq(_router.eFactory(), _eFactory);
    }

    function test_GovSetConfig_Integrity(address base, address quote, address oracle) public {
        vm.expectEmit();
        emit AxiomRouter.ConfigSet(base, quote, oracle);
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracle);

        assertEq(router.oracles(base, quote), oracle);
    }

    function test_GovSetConfig_Integrity_OverwriteOk(address base, address quote, address oracleA, address oracleB)
        public
    {
        vm.expectEmit();
        emit AxiomRouter.ConfigSet(base, quote, oracleA);
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracleA);

        vm.expectEmit();
        emit AxiomRouter.ConfigSet(base, quote, oracleB);
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
        emit AxiomRouter.ConfigUnset(base, quote);
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

    function test_IndexEVault_Integrity(address caller) public {
        address asset = makeAddr("asset");
        address vault = address(new StubERC4626(asset, 0));
        eFactory.setIsProxy(vault, true);

        vm.prank(caller);
        router.indexEVault(vault);
        assertEq(router.nestedVaults(vault), asset);
    }

    function test_IndexEVault_Integrity_Nested1(address caller) public {
        address asset = makeAddr("asset");
        address vault = address(new StubERC4626(asset, 0));
        address nVault = address(new StubERC4626(vault, 0));
        eFactory.setIsProxy(vault, true);
        eFactory.setIsProxy(nVault, true);

        vm.prank(caller);
        router.indexEVault(nVault);
        assertEq(router.nestedVaults(vault), asset);
        assertEq(router.nestedVaults(nVault), vault);
    }

    function test_IndexEVault_Integrity_Nested5(address caller) public {
        address asset = makeAddr("asset");
        address vault = address(new StubERC4626(asset, 0));
        address nVault = address(new StubERC4626(vault, 0));
        address nnVault = address(new StubERC4626(nVault, 0));
        address nnnVault = address(new StubERC4626(nnVault, 0));
        address nnnnVault = address(new StubERC4626(nnnVault, 0));
        address nnnnnVault = address(new StubERC4626(nnnnVault, 0));
        eFactory.setIsProxy(vault, true);
        eFactory.setIsProxy(nVault, true);
        eFactory.setIsProxy(nnVault, true);
        eFactory.setIsProxy(nnnVault, true);
        eFactory.setIsProxy(nnnnVault, true);
        eFactory.setIsProxy(nnnnnVault, true);

        vm.prank(caller);
        router.indexEVault(nnnnnVault);
        assertEq(router.nestedVaults(vault), asset);
        assertEq(router.nestedVaults(nVault), vault);
        assertEq(router.nestedVaults(nnVault), nVault);
        assertEq(router.nestedVaults(nnnVault), nnVault);
        assertEq(router.nestedVaults(nnnnVault), nnnVault);
        assertEq(router.nestedVaults(nnnnnVault), nnnnVault);
    }

    function test_IndexEVault_Integrity_NotEVault(address caller, address vault) public {
        vm.prank(caller);
        router.indexEVault(vault);
        assertEq(router.nestedVaults(vault), address(0));
    }

    function test_GetQuote_Integrity_BaseEqQuote(uint256 inAmount, address base, address oracle) public {
        base = boundAddr(base);
        oracle = boundAddr(oracle);
        vm.assume(base != oracle);
        inAmount = bound(inAmount, 1, type(uint128).max);
        uint256 outAmount = router.getQuote(inAmount, base, base);
        assertEq(outAmount, inAmount);
    }

    function test_GetQuote_Integrity_HasOracle(
        uint256 inAmount,
        address base,
        address quote,
        address oracle,
        uint256 outAmount
    ) public {
        base = boundAddr(base);
        quote = boundAddr(quote);
        oracle = boundAddr(oracle);
        vm.assume(base != quote && quote != oracle && base != oracle);
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.mockCall(
            oracle, abi.encodeWithSelector(IEOracle.getQuote.selector, inAmount, base, quote), abi.encode(outAmount)
        );
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracle);
        uint256 _outAmount = router.getQuote(inAmount, base, quote);
        assertEq(_outAmount, outAmount);
    }

    function test_GetQuote_Integrity_NoOracleButHasFallback(
        uint256 inAmount,
        address base,
        address quote,
        address fallbackOracle,
        uint256 outAmount
    ) public {
        base = boundAddr(base);
        quote = boundAddr(quote);
        fallbackOracle = boundAddr(fallbackOracle);
        vm.assume(base != quote && quote != fallbackOracle && base != fallbackOracle);
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.prank(GOVERNOR);
        router.govSetFallbackOracle(fallbackOracle);

        vm.mockCall(
            fallbackOracle,
            abi.encodeWithSelector(IEOracle.getQuote.selector, inAmount, base, quote),
            abi.encode(outAmount)
        );
        uint256 _outAmount = router.getQuote(inAmount, base, quote);
        assertEq(_outAmount, outAmount);
    }

    function test_GetQuote_RevertsWhen_NoOracleNoFallback(uint256 inAmount, address base, address quote) public {
        base = boundAddr(base);
        quote = boundAddr(quote);
        vm.assume(base != quote);
        inAmount = bound(inAmount, 1, type(uint128).max);

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        router.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_Properties(uint256 inAmount, uint256 i, uint256 j) public {
        eWETH = address(new StubERC4626(WETH, 1.2e18));
        eFactory.setIsProxy(eWETH, true);

        eeWETH = address(new StubERC4626(eWETH, 1.1e18));
        eFactory.setIsProxy(eeWETH, true);

        eDAI = address(new StubERC4626(DAI, 1.5e18));
        eFactory.setIsProxy(eDAI, true);

        eeDAI = address(new StubERC4626(eDAI, 1.25e18));
        eFactory.setIsProxy(eeDAI, true);

        eOracle = new StubEOracle();
        eOracle.setPrice(WETH, DAI, 2500e18);
        eOracle.setPrice(DAI, WETH, 0.0004e18);

        vm.prank(GOVERNOR);
        router.govSetConfig(WETH, DAI, address(eOracle));
        vm.prank(GOVERNOR);
        router.govSetConfig(DAI, WETH, address(eOracle));

        router.indexEVault(eeDAI);
        router.indexEVault(eeWETH);

        address[] memory tokens = new address[](6);
        tokens[0] = WETH;
        tokens[1] = eWETH;
        tokens[2] = eeWETH;
        tokens[3] = DAI;
        tokens[4] = eDAI;
        tokens[5] = eeDAI;

        inAmount = bound(inAmount, 1, type(uint128).max);
        i = bound(i, 0, tokens.length - 2);
        j = bound(j, i + 1, tokens.length - 1);

        uint256 outAmount_ij = router.getQuote(inAmount, tokens[i], tokens[j]);
        uint256 outAmount_ij_ji = router.getQuote(outAmount_ij, tokens[j], tokens[i]);

        assertApproxEqAbs(outAmount_ij_ji, inAmount, 10);
    }

    function test_GetQuote_ClosedLoopProperty(uint256 inAmount, LibPRNG.PRNG memory prng) public {
        eWETH = address(new StubERC4626(WETH, 1.2e18));
        eFactory.setIsProxy(eWETH, true);

        eeWETH = address(new StubERC4626(eWETH, 1.1e18));
        eFactory.setIsProxy(eeWETH, true);

        eDAI = address(new StubERC4626(DAI, 1.5e18));
        eFactory.setIsProxy(eDAI, true);

        eeDAI = address(new StubERC4626(eDAI, 1.25e18));
        eFactory.setIsProxy(eeDAI, true);

        eOracle = new StubEOracle();
        eOracle.setPrice(WETH, DAI, 2500e18);
        eOracle.setPrice(DAI, WETH, 0.0004e18);

        vm.prank(GOVERNOR);
        router.govSetConfig(WETH, DAI, address(eOracle));
        vm.prank(GOVERNOR);
        router.govSetConfig(DAI, WETH, address(eOracle));

        router.indexEVault(eeDAI);
        router.indexEVault(eeWETH);

        address[] memory tokens = new address[](6);
        tokens[0] = WETH;
        tokens[1] = eWETH;
        tokens[2] = eeWETH;
        tokens[3] = DAI;
        tokens[4] = eDAI;
        tokens[5] = eeDAI;

        _shuffle(prng, tokens);

        inAmount = bound(inAmount, 1e18, type(uint128).max);

        uint256 initInAmount = inAmount;

        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 j = (i + 1) % tokens.length;
            inAmount = router.getQuote(inAmount, tokens[i], tokens[j]);
        }
        assertApproxEqRel(initInAmount, inAmount, 0.00000001e18);
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

    function _shuffle(LibPRNG.PRNG memory prng, address[] memory a) private pure {
        uint256[] memory a_;
        assembly {
            a_ := a
        }
        LibPRNG.shuffle(prng, a_);
    }
}
