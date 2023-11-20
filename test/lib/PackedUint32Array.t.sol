// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {PackedUint32Array, PackedUint32ArrayLib} from "src/lib/PackedUint32Array.sol";

contract PackedUint32ArrayTest is Test {
    function test_From_RevertsWhen_TooLarge(uint256[] memory values) public {
        uint256 numValues = values.length;
        vm.assume(numValues > PackedUint32ArrayLib.MAX_INDEX + 1);
        values = _boundValueArray(values);

        vm.expectRevert(_indexOOBError(PackedUint32ArrayLib.MAX_INDEX + 1));
        PackedUint32ArrayLib.from(values);
    }

    function test_From_Integrity(uint256[] memory values) public {
        uint256 numValues = values.length;
        vm.assume(numValues <= PackedUint32ArrayLib.MAX_INDEX + 1);
        values = _boundValueArray(values);

        PackedUint32Array array = PackedUint32ArrayLib.from(values);
        for (uint256 i = 0; i < numValues; ++i) {
            assertEq(array.get(i), values[i]);
        }
    }

    function test_From_Empty_Integrity(uint256 index) public {
        index = _boundIndex(index);

        PackedUint32Array array = PackedUint32ArrayLib.from(new uint256[](index));
        assertEq(array.get(index), 0);
    }

    function test_Get_RevertsWhen_IndexOOB(PackedUint32Array array, uint256 index) public {
        index = _boundIndexOOB(index);

        vm.expectRevert(_indexOOBError(index));
        array.get(index);
    }

    function test_Set_Integrity(PackedUint32Array array, uint256 index, uint256 value) public {
        index = _boundIndex(index);
        value = _boundValue(value);

        array = array.set(index, value);
        assertEq(array.get(index), value);
    }

    function test_Set_RevertsWhen_IndexOOB(PackedUint32Array array, uint256 index, uint256 value) public {
        index = _boundIndexOOB(index);
        value = _boundValue(value);

        vm.expectRevert(_indexOOBError(index));
        array.set(index, value);
    }

    function test_Set_RevertsWhen_ValueOOB(PackedUint32Array array, uint256 index, uint256 value) public {
        index = _boundIndex(index);
        value = _boundValueOOB(value);

        vm.expectRevert(_valueOOBError(value));
        array.set(index, value);
    }

    function test_SetGet_Integrity(PackedUint32Array array, uint256 index, uint256 value) public {
        index = _boundIndex(index);
        value = _boundValue(value);

        array = array.set(index, value);
        assertEq(array.get(index), value);
    }

    function test_Sum_Integrity(uint256[] memory values) public {
        uint256 numValues = values.length;
        vm.assume(numValues <= PackedUint32ArrayLib.MAX_INDEX + 1);
        values = _boundValueArray(values);

        PackedUint32Array array = PackedUint32ArrayLib.from(values);

        uint256 expectedSum;
        for (uint256 i = 0; i < numValues; ++i) {
            expectedSum += values[i];
        }

        assertEq(expectedSum, array.sum());
    }

    function test_Sum_Integrity_Get(PackedUint32Array array) public {
        uint256 expectedSum;
        for (uint256 i = 0; i <= PackedUint32ArrayLib.MAX_INDEX; ++i) {
            expectedSum += array.get(i);
        }

        assertEq(expectedSum, array.sum());
    }

    function test_Eq_InverseOf_Neq(PackedUint32Array arrayA, PackedUint32Array arrayB) public {
        bool eq = arrayA.eq(arrayB);
        bool neq = arrayA.neq(arrayB);
        assertEq(eq, !neq);
    }

    function test_Eq_FalseWhen_DiffValue(PackedUint32Array array, uint256 index, uint256 value) public {
        index = _boundIndex(index);
        value = _boundValue(value);
        vm.assume(value != array.get(index));

        PackedUint32Array $array = array.set(index, value);
        bool eq = array.eq($array);
        assertFalse(eq);
    }

    function test_Clear_Integrity(PackedUint32Array array, uint256 index) public {
        index = _boundIndex(index);

        array = array.clear(index);
        assertEq(array.get(index), 0);
    }

    function test_Clear_RevertsWhen_IndexOOB(PackedUint32Array array, uint256 index) public {
        index = _boundIndexOOB(index);

        vm.expectRevert(_indexOOBError(index));
        array.clear(index);
    }

    function _boundIndex(uint256 index) private view returns (uint256) {
        return bound(index, 0, PackedUint32ArrayLib.MAX_INDEX);
    }

    function _boundIndexOOB(uint256 index) private view returns (uint256) {
        return bound(index, PackedUint32ArrayLib.MAX_INDEX + 1, type(uint256).max);
    }

    function _boundValue(uint256 value) private view returns (uint256) {
        return bound(value, 0, PackedUint32ArrayLib.MAX_VALUE);
    }

    function _boundValueOOB(uint256 value) private view returns (uint256) {
        return bound(value, PackedUint32ArrayLib.MAX_VALUE + 1, type(uint256).max);
    }

    function _boundValueArray(uint256[] memory values) private view returns (uint256[] memory) {
        uint256 numValues = values.length;
        for (uint256 i = 0; i < numValues; ++i) {
            values[i] = _boundValue(values[i]);
        }

        return values;
    }

    function _indexOOBError(uint256 index) private pure returns (bytes memory) {
        return abi.encodeWithSelector(PackedUint32ArrayLib.IndexOOB.selector, index);
    }

    function _valueOOBError(uint256 value) private pure returns (bytes memory) {
        return abi.encodeWithSelector(PackedUint32ArrayLib.ValueOOB.selector, value);
    }
}
