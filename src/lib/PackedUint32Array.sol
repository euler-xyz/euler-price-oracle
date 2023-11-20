// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

type PackedUint32Array is uint256;

using PackedUint32ArrayLib for PackedUint32Array global;

library PackedUint32ArrayLib {
    uint256 internal constant MAX_VALUE = uint256(type(uint32).max);
    uint256 internal constant MAX_INDEX = 7;
    uint256 internal constant MAX_LENGTH = 8;
    uint256 internal constant MASK = 0x00000000000000000000000000000000000000000000000000000000FFFFFFFF;

    error IndexOOB(uint256 index);
    error ValueOOB(uint256 value);

    function from(uint256[] memory inArray) internal pure returns (PackedUint32Array) {
        uint256 length = inArray.length;
        if (length == 0) return PackedUint32Array.wrap(0);
        if (length > MAX_LENGTH) revert IndexOOB(MAX_LENGTH);

        PackedUint32Array array;
        for (uint256 index = length - 1; index != type(uint256).max;) {
            uint256 value = inArray[index];
            if (value > MAX_VALUE) revert ValueOOB(value);

            uint256 offset = index << 5;
            array = PackedUint32Array.wrap(PackedUint32Array.unwrap(array) | (value << offset));
            unchecked {
                --index;
            }
        }

        return array;
    }

    function get(PackedUint32Array array, uint256 index) internal pure returns (uint256) {
        if (index > MAX_INDEX) revert IndexOOB(index);

        uint256 offset = index << 5;
        return (PackedUint32Array.unwrap(array) & (MASK << offset)) >> offset;
    }

    function set(PackedUint32Array array, uint256 index, uint256 value) internal pure returns (PackedUint32Array) {
        if (index > MAX_INDEX) revert IndexOOB(index);
        if (value > MAX_VALUE) revert ValueOOB(value);

        uint256 offset = index << 5;
        return PackedUint32Array.wrap((PackedUint32Array.unwrap(array) & ~(MASK << offset)) | (value << offset));
    }

    function clear(PackedUint32Array array, uint256 index) internal pure returns (PackedUint32Array) {
        if (index > MAX_INDEX) revert IndexOOB(index);

        uint256 offset = index << 5;
        return PackedUint32Array.wrap((PackedUint32Array.unwrap(array) & ~(MASK << offset)));
    }

    function mask(PackedUint32Array array, PackedUint32Array bitMask) internal pure returns (PackedUint32Array) {
        return PackedUint32Array.wrap(PackedUint32Array.unwrap(array) & PackedUint32Array.unwrap(bitMask));
    }

    function sum(PackedUint32Array array) internal pure returns (uint256) {
        uint256 total;
        uint256 mask = MASK;

        for (uint256 offset = 0; offset < 255;) {
            uint256 value = (PackedUint32Array.unwrap(array) & (MASK << offset)) >> offset;
            unchecked {
                total = total + value;
                offset = offset + 32;
            }
        }
        return total;
    }

    function eq(PackedUint32Array arrayA, PackedUint32Array arrayB) internal pure returns (bool) {
        return PackedUint32Array.unwrap(arrayA) == PackedUint32Array.unwrap(arrayB);
    }

    function neq(PackedUint32Array arrayA, PackedUint32Array arrayB) internal pure returns (bool) {
        return PackedUint32Array.unwrap(arrayA) != PackedUint32Array.unwrap(arrayB);
    }
}
