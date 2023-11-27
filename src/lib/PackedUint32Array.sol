// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

type PackedUint32Array is uint256;

using PackedUint32ArrayLib for PackedUint32Array global;

/// @author totomanov
/// @notice A custom type that stores 8 32-bit unsigned integers.
/// @dev Used for timestamps and masks in strategy contracts.
/// Although the elements are uint32s, library methods operate only on uint256s.
library PackedUint32ArrayLib {
    uint256 internal constant MAX_VALUE = uint256(type(uint32).max);
    uint256 internal constant MAX_INDEX = 7;
    uint256 internal constant MAX_LENGTH = 8;
    uint256 internal constant MASK = 0x00000000000000000000000000000000000000000000000000000000FFFFFFFF;

    error IndexOOB(uint256 index);
    error ValueOOB(uint256 value);

    /// @notice Construct a new `PackedUint32Array` from a uint256 array.
    /// @dev Packs the values in a single uint256.
    /// @param inArray The array of values to pack.
    /// @return The PackedUint32Array value.
    /// Reverts if the array has more than 8 elements.
    /// Reverts if the array contains a value greater than 2^32-1.
    function from(uint256[] memory inArray) internal pure returns (PackedUint32Array) {
        uint256 length = inArray.length;
        if (length == 0) return PackedUint32Array.wrap(0);
        if (length > MAX_LENGTH) revert IndexOOB(MAX_LENGTH);

        PackedUint32Array array;
        /// Pack them in reverse order for efficiency (only shift left)
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

    /// @notice Get the value at position `index`.
    /// @return The element at the given index.
    function get(PackedUint32Array array, uint256 index) internal pure returns (uint256) {
        if (index > MAX_INDEX) revert IndexOOB(index);

        uint256 offset = index << 5;
        return (PackedUint32Array.unwrap(array) & (MASK << offset)) >> offset;
    }

    /// @notice Set the value at position `index` to `value`.
    /// @return The mutated `PackedUint32Array`.
    function set(PackedUint32Array array, uint256 index, uint256 value) internal pure returns (PackedUint32Array) {
        if (index > MAX_INDEX) revert IndexOOB(index);
        if (value > MAX_VALUE) revert ValueOOB(value);

        uint256 offset = index << 5;
        return PackedUint32Array.wrap((PackedUint32Array.unwrap(array) & ~(MASK << offset)) | (value << offset));
    }

    /// @notice Set the value at position `index` to 0.
    /// @dev Slightly more gas-efficient than calling `set`.
    /// @return The mutated `PackedUint32Array`.
    function clear(PackedUint32Array array, uint256 index) internal pure returns (PackedUint32Array) {
        if (index > MAX_INDEX) revert IndexOOB(index);

        uint256 offset = index << 5;
        return PackedUint32Array.wrap((PackedUint32Array.unwrap(array) & ~(MASK << offset)));
    }

    /// @notice Apply a bitmask to the array.
    /// @dev NOTE: `bitmask` MUST have 32 1-bits for each selected element.
    /// @return The masked `PackedUint32Array`.
    function mask(PackedUint32Array array, PackedUint32Array bitmask) internal pure returns (PackedUint32Array) {
        return PackedUint32Array.wrap(PackedUint32Array.unwrap(array) & PackedUint32Array.unwrap(bitmask));
    }

    /// @notice Sum over the elements in the array.
    /// @dev Overflow impossible since each element is max 32 bits.
    /// @return The sum.
    function sum(PackedUint32Array array) internal pure returns (uint256) {
        uint256 total;
        for (uint256 offset = 0; offset < 255;) {
            uint256 value = (PackedUint32Array.unwrap(array) & (MASK << offset)) >> offset;
            unchecked {
                total = total + value;
                offset = offset + 32;
            }
        }
        return total;
    }

    /// @notice Check if two arrays are element-wise equal.
    function eq(PackedUint32Array arrayA, PackedUint32Array arrayB) internal pure returns (bool) {
        return PackedUint32Array.unwrap(arrayA) == PackedUint32Array.unwrap(arrayB);
    }

    /// @notice Check if two arrays are not element-wise equal.
    function neq(PackedUint32Array arrayA, PackedUint32Array arrayB) internal pure returns (bool) {
        return !eq(arrayA, arrayB)
    }
}
