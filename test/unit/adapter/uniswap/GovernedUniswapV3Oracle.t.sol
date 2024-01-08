// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3PoolImmutables} from "@uniswap/v3-core/contracts/interfaces/pool/IUniswapV3PoolImmutables.sol";
import {GovernedUniswapV3Oracle} from "src/adapter/uniswap/GovernedUniswapV3Oracle.sol";
import {UniswapV3Config, UniswapV3ConfigLib} from "src/adapter/uniswap/UniswapV3Config.sol";
import {IFactoryInitializable} from "src/interfaces/IFactoryInitializable.sol";
import {Errors} from "src/lib/Errors.sol";

contract GovernedUniswapV3OracleTest is Test {
    address constant UNISWAP_V3_FACTORY = address(0x3333);
    address internal GOVERNOR = makeAddr("GOVERNOR");
    GovernedUniswapV3Oracle oracle;

    function setUp() public {
        oracle = new GovernedUniswapV3Oracle(UNISWAP_V3_FACTORY);
        oracle.initialize(GOVERNOR);
    }

    function test_Constructor_Integrity() public {
        assertEq(address(oracle.uniswapV3Factory()), UNISWAP_V3_FACTORY);
    }

    function test_GovSetConfig_Integrity(
        address pool,
        uint24 twapWindow,
        address token0,
        address token1,
        uint24 fee,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) public {
        pool = boundAddr(pool);
        token0 = boundAddr(token0);
        token1 = boundAddr(token1);
        vm.assume(twapWindow != 0);
        vm.assume(token0 != token1);
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.token0.selector), abi.encode(token0));
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.token1.selector), abi.encode(token1));
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.fee.selector), abi.encode(fee));
        vm.mockCall(
            UNISWAP_V3_FACTORY,
            abi.encodeWithSelector(IUniswapV3Factory.getPool.selector, token0, token1, fee),
            abi.encode(pool)
        );
        vm.mockCall(token0, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token0Decimals));
        vm.mockCall(token1, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token1Decimals));
        vm.prank(GOVERNOR);
        oracle.govSetConfig(pool, twapWindow);

        UniswapV3Config config = oracle.configs(token0, token1);
        assertEq(config.getPool(), pool);
        assertEq(config.getValidUntil(), type(uint32).max);
        assertEq(config.getTwapWindow(), twapWindow);
        assertEq(config.getFee(), fee);
        assertEq(config.getToken0Decimals(), token0Decimals);
        assertEq(config.getToken1Decimals(), token1Decimals);
    }

    function test_GovSetConfig_RevertsWhen_NotGovernor(
        address pool,
        uint24 twapWindow,
        address token0,
        address token1,
        uint24 fee,
        uint8 token0Decimals,
        uint8 token1Decimals,
        address caller
    ) public {
        vm.assume(caller != GOVERNOR);
        pool = boundAddr(pool);
        token0 = boundAddr(token0);
        token1 = boundAddr(token1);
        vm.assume(twapWindow != 0);
        vm.assume(token0 != token1);
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.token0.selector), abi.encode(token0));
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.token1.selector), abi.encode(token1));
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.fee.selector), abi.encode(fee));
        vm.mockCall(
            UNISWAP_V3_FACTORY,
            abi.encodeWithSelector(IUniswapV3Factory.getPool.selector, token0, token1, fee),
            abi.encode(pool)
        );
        vm.mockCall(token0, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token0Decimals));
        vm.mockCall(token1, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token1Decimals));
        vm.expectRevert(IFactoryInitializable.CallerNotGovernor.selector);
        vm.prank(caller);
        oracle.govSetConfig(pool, twapWindow);
    }

    function test_GovSetConfig_RevertsWhen_PoolMismatch(
        address pool,
        address factoryPool,
        uint24 twapWindow,
        address token0,
        address token1,
        uint24 fee,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) public {
        pool = boundAddr(pool);
        token0 = boundAddr(token0);
        token1 = boundAddr(token1);
        vm.assume(twapWindow != 0);
        vm.assume(token0 != token1);
        vm.assume(pool != factoryPool);

        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.token0.selector), abi.encode(token0));
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.token1.selector), abi.encode(token1));
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.fee.selector), abi.encode(fee));
        vm.mockCall(
            UNISWAP_V3_FACTORY,
            abi.encodeWithSelector(IUniswapV3Factory.getPool.selector, token0, token1, fee),
            abi.encode(factoryPool)
        );
        vm.mockCall(token0, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token0Decimals));
        vm.mockCall(token1, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token1Decimals));
        vm.expectRevert(abi.encodeWithSelector(Errors.UniswapV3_PoolMismatch.selector, pool, factoryPool));
        vm.prank(GOVERNOR);
        oracle.govSetConfig(pool, twapWindow);
    }

    function test_GovUnsetConfig_Integrity(
        address pool,
        uint24 twapWindow,
        address token0,
        address token1,
        uint24 fee,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) public {
        pool = boundAddr(pool);
        token0 = boundAddr(token0);
        token1 = boundAddr(token1);
        vm.assume(twapWindow != 0);
        vm.assume(token0 != token1);
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.token0.selector), abi.encode(token0));
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.token1.selector), abi.encode(token1));
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.fee.selector), abi.encode(fee));
        vm.mockCall(
            UNISWAP_V3_FACTORY,
            abi.encodeWithSelector(IUniswapV3Factory.getPool.selector, token0, token1, fee),
            abi.encode(pool)
        );
        vm.mockCall(token0, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token0Decimals));
        vm.mockCall(token1, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(token1Decimals));
        vm.prank(GOVERNOR);
        oracle.govSetConfig(pool, twapWindow);

        vm.prank(GOVERNOR);
        oracle.govUnsetConfig(pool);
        UniswapV3Config config = oracle.configs(token0, token1);
        assertEq(config.getPool(), address(0));
        assertEq(config.getValidUntil(), 0);
        assertEq(config.getTwapWindow(), 0);
        assertEq(config.getFee(), 0);
        assertEq(config.getToken0Decimals(), 0);
        assertEq(config.getToken1Decimals(), 0);
    }

    function test_GovUnsetConfig_NoConfigOk(address pool, address token0, address token1) public {
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.token0.selector), abi.encode(token0));
        vm.mockCall(address(pool), abi.encodeWithSelector(IUniswapV3PoolImmutables.token1.selector), abi.encode(token1));
        vm.prank(GOVERNOR);
        oracle.govUnsetConfig(pool);
        UniswapV3Config config = oracle.configs(token0, token1);
        assertEq(config.getPool(), address(0));
        assertEq(config.getValidUntil(), 0);
        assertEq(config.getTwapWindow(), 0);
        assertEq(config.getFee(), 0);
        assertEq(config.getToken0Decimals(), 0);
        assertEq(config.getToken1Decimals(), 0);
    }

    function test_GovUnsetConfig_RevertsWhen_CallerNotGovernor(address caller, address pool) public {
        vm.assume(caller != GOVERNOR);
        vm.prank(caller);
        vm.expectRevert(IFactoryInitializable.CallerNotGovernor.selector);
        oracle.govUnsetConfig(pool);
    }
}
