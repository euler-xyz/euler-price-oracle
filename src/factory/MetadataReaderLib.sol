// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

struct MetadataReader {
    uint256 length;
    uint256 cursor;
    uint256 dataPtr;
}

library MetadataReaderLib {
    uint256 private constant UINT8_LENGTH = 1;
    uint256 private constant UINT256_LENGTH = 32;
    uint256 private constant ADDRESS_LENGTH = 20;

    error CursorOOB(uint256 nextCursor, uint256 length);

    function init() internal pure returns (MetadataReader memory) {
        uint256 length;
        uint256 dataPtr;
        assembly ("memory-safe") {
            let lengthPtr := sub(calldatasize(), 32)
            length := calldataload(lengthPtr)
            dataPtr := sub(lengthPtr, length)
        }

        return MetadataReader({length: length, cursor: 0, dataPtr: dataPtr});
    }

    function readUint8(MetadataReader memory reader) internal pure returns (address v) {
        bytes32 r = _read(reader, UINT8_LENGTH);
        assembly ("memory-safe") {
            v := r
        }
    }

    function readUint256(MetadataReader memory reader) internal pure returns (uint256 v) {
        bytes32 r = _read(reader, UINT256_LENGTH);
        assembly ("memory-safe") {
            v := r
        }
    }

    function readAddress(MetadataReader memory reader) internal pure returns (address v) {
        bytes32 r = _read(reader, ADDRESS_LENGTH);
        assembly ("memory-safe") {
            v := r
        }
    }

    function _read(MetadataReader memory reader, uint256 valueLength) internal pure returns (bytes32 v) {
        uint256 length = reader.length;
        uint256 cursor = reader.cursor;
        uint256 dataPtr = reader.dataPtr;
        uint256 nextCursor = cursor + valueLength;
        if (nextCursor > length) revert CursorOOB(nextCursor, length);
        reader.cursor = nextCursor;
        reader.dataPtr = reader.dataPtr + valueLength;
        assembly ("memory-safe") {
            v := calldataload(dataPtr)
            if lt(valueLength, 0x20) { v := shr(sub(0x20, valueLength), v) }
        }
    }
}
