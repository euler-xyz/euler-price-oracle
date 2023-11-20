// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

type PackedUint32Array is uint256;

using PackedUint32ArrayLib for PackedUint32Array global;

library PackedUint32ArrayLib {
    uint256 internal constant MAX_VALUE = uint256(type(uint32).max);
    uint256 internal constant MAX_INDEX = 7;
    uint256 internal constant VALUE_BITS = 32;
    uint256 internal constant MASK = 0x00000000000000000000000000000000000000000000000000000000FFFFFFFF;

    error ValueOOB(uint256 value, uint256 maxValue);
    error IndexOOB(uint256 index, uint256 maxIndex);

    function get(PackedUint32Array array, uint256 index) internal pure returns (uint256) {
        _checkIndex(index);

        uint256 offset = _getOffset(index);
        return (PackedUint32Array.unwrap(array) & (MASK << offset)) >> offset;
    }

    function set(PackedUint32Array array, uint256 index, uint256 value) internal pure returns (PackedUint32Array) {
        _checkIndex(index);
        _checkValue(value);

        uint256 offset = _getOffset(index);
        return PackedUint32Array.wrap((PackedUint32Array.unwrap(array) & ~(MASK << offset)) | (value << offset));
    }

    function clear(PackedUint32Array array, uint256 index) internal pure returns (PackedUint32Array) {
        _checkIndex(index);

        uint256 offset = _getOffset(index);
        return PackedUint32Array.wrap((PackedUint32Array.unwrap(array) & ~(MASK << offset)));
    }

    function eq(PackedUint32Array arrayA, PackedUint32Array arrayB) internal pure returns (bool) {
        return PackedUint32Array.unwrap(arrayA) == PackedUint32Array.unwrap(arrayB);
    }

    function neq(PackedUint32Array arrayA, PackedUint32Array arrayB) internal pure returns (bool) {
        return PackedUint32Array.unwrap(arrayA) != PackedUint32Array.unwrap(arrayB);
    }

    function _checkIndex(uint256 index) private pure {
        if (index > MAX_INDEX) revert IndexOOB(index, MAX_INDEX);
    }

    function _checkValue(uint256 value) private pure {
        if (value > MAX_VALUE) revert ValueOOB(value, MAX_VALUE);
    }

    /// @dev todo optimize this with shl
    function _getOffset(uint256 index) private pure returns (uint256) {
        return index * VALUE_BITS;
    }
}
