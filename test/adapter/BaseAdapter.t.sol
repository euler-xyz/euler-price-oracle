// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {BaseAdapterHarness} from "test/adapter/BaseAdapterHarness.sol";
import {boundAddr} from "test/utils/TestUtils.sol";

contract BaseAdapterTest is Test {
    uint160 internal constant ADDRESS_RESERVED_RANGE = 0xffffffff;
    BaseAdapterHarness oracle;

    function setUp() public {
        oracle = new BaseAdapterHarness();
    }

    function test_GetDecimals_Integrity_ReservedRange(address x) public view {
        x = address(uint160(x) % ADDRESS_RESERVED_RANGE);
        assertEq(oracle.getDecimals(x), 18);
    }

    function test_GetDecimals_Integrity_ERC20(address x, uint8 decimals) public {
        x = boundAddr(x);
        vm.assume(uint160(x) > ADDRESS_RESERVED_RANGE);
        vm.mockCall(x, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        uint8 _decimals = oracle.getDecimals(x);
        assertEq(_decimals, decimals);
    }

    function test_GetDecimals_Integrity_nonERC20(address x) public view {
        x = boundAddr(x);
        vm.assume(uint160(x) > ADDRESS_RESERVED_RANGE);

        uint8 decimals = oracle.getDecimals(x);
        assertEq(decimals, 18);
    }
}
