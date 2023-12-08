// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {ImmutableAddressArrayHarness} from "test/utils/ImmutableAddressArrayHarness.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";

contract ImmutableAddressArrayTest is Test {
    function test_Constructor_RevertsWhen_Empty() public {
        vm.expectRevert(ImmutableAddressArray.ArrayEmpty.selector);
        new ImmutableAddressArrayHarness(new address[](0));
    }

    function test_Constructor_RevertsWhen_TooLarge(address[] memory array) public {
        vm.assume(array.length > 8);
        vm.expectRevert(abi.encodeWithSelector(ImmutableAddressArray.ArrayTooLarge.selector, array.length, 8));
        new ImmutableAddressArrayHarness(array);
    }

    function test_Constructor_Integrity(address[] memory array) public {
        uint256 length = array.length;
        vm.assume(length > 0 && length <= 8);
        ImmutableAddressArrayHarness harness = new ImmutableAddressArrayHarness(array);

        assertEq(harness.getCardinality(), length);

        for (uint256 i = 0; i < length; ++i) {
            assertEq(harness.get(i), array[i]);
        }
    }

    function test_Get_RevertsWhen_IndexOOB(address[] memory array, uint256 index) public {
        uint256 length = array.length;
        vm.assume(length > 0 && length <= 8);
        index = bound(index, length + 1, type(uint256).max);
        ImmutableAddressArrayHarness harness = new ImmutableAddressArrayHarness(array);

        vm.expectRevert(abi.encodeWithSelector(ImmutableAddressArray.IndexOOB.selector, index, length - 1));
        harness.get(index);
    }
}
