// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {UniswapV3Config, UniswapV3ConfigLib} from "src/adapter/uniswap/UniswapV3Config.sol";
import {GovernedUniswapV3Oracle} from "src/adapter/uniswap/GovernedUniswapV3Oracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract GovernedUniswapV3OracleTest is Test {
    address constant UNISWAP_V3_FACTORY = address(0x3333);
    GovernedUniswapV3Oracle oracle;

    function setUp() public {
        oracle = new GovernedUniswapV3Oracle(UNISWAP_V3_FACTORY);
    }

    function test_Constructor_Integrity() public {
        assertEq(address(oracle.uniswapV3Factory()), UNISWAP_V3_FACTORY);
    }

    function test_GovSetConfig_RevertsWhen_NotGovernor(address pool, uint24 twapWindow) public {
        vm.expectRevert(abi.encodeWithSelector(Errors.UniswapV3_NoPool.selector, base, quote));
        oracle.updateConfig(base, quote);
    }
}
