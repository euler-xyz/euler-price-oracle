// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {ERC4626} from "@solady/tokens/ERC4626.sol";
import {LibPRNG} from "@solady/utils/LibPRNG.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {EdgeRouter} from "src/strategy/router/EdgeRouter.sol";

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

contract EdgeRouterTest is Test {
    address GOVERNOR = makeAddr("GOVERNOR");
    EdgeRouter router;

    address WETH = makeAddr("WETH");
    address eWETH;
    address eeWETH;

    address DAI = makeAddr("DAI");
    address eDAI;
    address eeDAI;

    StubEOracle eOracle;

    function setUp() public {
        router = new EdgeRouter();
        router.initialize(GOVERNOR);
    }

    function test_Constructor_Integrity() public {
        assertEq(router.fallbackOracle(), address(0));
    }

    function test_GovSetConfig_Integrity(address base, address quote, address oracle) public {
        vm.expectEmit();
        emit EdgeRouter.ConfigSet(base, quote, oracle);
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracle);

        assertEq(router.oracles(base, quote), oracle);
    }

    function test_GovSetConfig_Integrity_OverwriteOk(address base, address quote, address oracleA, address oracleB)
        public
    {
        vm.expectEmit();
        emit EdgeRouter.ConfigSet(base, quote, oracleA);
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracleA);

        vm.expectEmit();
        emit EdgeRouter.ConfigSet(base, quote, oracleB);
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
        vm.prank(caller);
        router.govSetConfig(base, quote, oracle);
    }

    function test_GovClearConfig_Integrity(address base, address quote, address oracle) public {
        vm.prank(GOVERNOR);
        router.govSetConfig(base, quote, oracle);

        vm.expectEmit();
        emit EdgeRouter.ConfigSet(base, quote, address(0));
        vm.prank(GOVERNOR);
        router.govClearConfig(base, quote);

        assertEq(router.oracles(base, quote), address(0));
    }

    function test_GovClearConfig_NoConfigOk(address base, address quote) public {
        vm.prank(GOVERNOR);
        router.govClearConfig(base, quote);

        assertEq(router.oracles(base, quote), address(0));
    }

    function test_GovClearConfig_RevertsWhen_CallerNotGovernor(address caller, address base, address quote) public {
        vm.assume(caller != GOVERNOR);

        vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
        vm.prank(caller);
        router.govClearConfig(base, quote);
    }

    function test_GovSetVaultResolver_Integrity(address vault, address asset) public {
        vault = boundAddr(vault);
        vm.mockCall(vault, abi.encodeWithSelector(ERC4626.asset.selector), abi.encode(asset));
        vm.expectEmit();
        emit EdgeRouter.ResolvedVaultSet(vault, asset);

        vm.prank(GOVERNOR);
        router.govSetResolvedVault(vault);

        assertEq(router.resolvedVaults(vault), asset);
    }

    function test_GovSetVaultResolver_Integrity_OverwriteOk(address vault, address assetA, address assetB) public {
        vault = boundAddr(vault);
        vm.mockCall(vault, abi.encodeWithSelector(ERC4626.asset.selector), abi.encode(assetA));
        vm.prank(GOVERNOR);
        router.govSetResolvedVault(vault);

        vm.mockCall(vault, abi.encodeWithSelector(ERC4626.asset.selector), abi.encode(assetB));
        vm.prank(GOVERNOR);
        router.govSetResolvedVault(vault);

        assertEq(router.resolvedVaults(vault), assetB);
    }

    function test_GovSetVaultResolver_RevertsWhen_CallerNotGovernor(address caller, address vault) public {
        vm.assume(caller != GOVERNOR);

        vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
        vm.prank(caller);
        router.govSetResolvedVault(vault);
    }

    function test_GovClearResolvedVault_Integrity(address vault, address asset) public {
        vault = boundAddr(vault);
        vm.mockCall(vault, abi.encodeWithSelector(ERC4626.asset.selector), abi.encode(asset));

        vm.prank(GOVERNOR);
        router.govSetResolvedVault(vault);

        vm.expectEmit();
        emit EdgeRouter.ResolvedVaultSet(vault, address(0));
        vm.prank(GOVERNOR);
        router.govClearResolvedVault(vault);

        assertEq(router.resolvedVaults(vault), address(0));
    }

    function test_GovClearResolvedVault_NoConfigOk(address vault, address asset) public {
        vault = boundAddr(vault);
        vm.mockCall(vault, abi.encodeWithSelector(ERC4626.asset.selector), abi.encode(asset));

        vm.prank(GOVERNOR);
        router.govClearResolvedVault(vault);

        assertEq(router.resolvedVaults(vault), address(0));
    }

    function test_GovClearResolvedVault_RevertsWhen_CallerNotGovernor(address caller, address vault) public {
        vm.assume(caller != GOVERNOR);

        vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
        vm.prank(caller);
        router.govClearResolvedVault(vault);
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
        vm.prank(caller);
        router.govSetFallbackOracle(fallbackOracle);
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

    function test_GetQuote_InverseProperty(uint256 inAmount, uint256 i, uint256 j) public {
        eWETH = address(new StubERC4626(WETH, 1.2e18));
        eeWETH = address(new StubERC4626(eWETH, 1.1e18));
        eDAI = address(new StubERC4626(DAI, 1.5e18));
        eeDAI = address(new StubERC4626(eDAI, 1.25e18));

        eOracle = new StubEOracle();
        eOracle.setPrice(WETH, DAI, 2500e18);
        eOracle.setPrice(DAI, WETH, 0.0004e18);

        vm.startPrank(GOVERNOR);
        router.govSetConfig(WETH, DAI, address(eOracle));
        router.govSetConfig(DAI, WETH, address(eOracle));
        router.govSetResolvedVault(eDAI);
        router.govSetResolvedVault(eeDAI);
        router.govSetResolvedVault(eWETH);
        router.govSetResolvedVault(eeWETH);
        vm.stopPrank();

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
        eeWETH = address(new StubERC4626(eWETH, 1.1e18));
        eDAI = address(new StubERC4626(DAI, 1.5e18));
        eeDAI = address(new StubERC4626(eDAI, 1.25e18));

        eOracle = new StubEOracle();
        eOracle.setPrice(WETH, DAI, 2500e18);
        eOracle.setPrice(DAI, WETH, 0.0004e18);

        vm.startPrank(GOVERNOR);
        router.govSetConfig(WETH, DAI, address(eOracle));
        router.govSetConfig(DAI, WETH, address(eOracle));
        router.govSetResolvedVault(eDAI);
        router.govSetResolvedVault(eeDAI);
        router.govSetResolvedVault(eWETH);
        router.govSetResolvedVault(eeWETH);
        vm.stopPrank();

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
