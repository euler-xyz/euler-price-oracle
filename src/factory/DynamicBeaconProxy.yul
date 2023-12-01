// SPDX-License-Identifier: GPL-2.0-or-later
object "DynamicBeaconProxy" {
    code {
        function allocate(size) -> ptr {
            ptr := mload(0x40)
            // Note that Solidity generated IR code reserves memory offset ``0x60`` as well, but a pure Yul object is free to use memory as it chooses.
            if iszero(ptr) { ptr := 0x60 }
            mstore(0x40, add(ptr, size))
        }

        mstore(0, 0x5c60da1b00000000000000000000000000000000000000000000000000000000)
        log(0, 4)
        mstore(0, 0)
        // emit Genesis();

        let codesize := datasize("runtime")
        let tdsize := add(calldatasize(), 0x40)
        let offset := allocate(add(codesize, tdsize))
        // copy the runtime code with CODECOPY
        datacopy(offset, dataoffset("runtime"), codesize)
        
        // now we need to append the immutables to the runtime code (todo - invalid opcode to separate them)
        // constructor parameters here (bytes memory trailingData)
        let ioffset := add(offset, codesize) // free mem size: calldatasize() + 0x40 
        mstore(ioffset, caller()) // first immutable is caller // free mem size: calldatasize + 0x20
        sstore(0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50, caller())  // Store the beacon address in ERC-1967 slot
        calldatacopy(add(ioffset, 0x20), 0, calldatasize()) // copy the calldata as the next immutable // free mem size: 0x20
        let metadataLengthOffset := add(ioffset, 0x20)
        // add 32 bits to metadataLength
        mstore(metadataLengthOffset, add(mload(metadataLengthOffset), 0x20))

        // Append the size of the trailing data for ERC-3448 compatibility
        mstore(add(ioffset, calldatasize()), calldatasize())

        // deploy runtime code + appended data
        return(0, add(codesize, tdsize))
    }

    object "runtime" {
        code {
            codecopy(0, sub(codesize(), 0x20), 0x20) // mstore(0, metadataLength)
            let immutables_offset := 0x60 // 0x00 - metadataLength, 0x20 - beacon, 0x40 - implementation selector, 0x60 - immutables
            let metadataLength := mload(0)
            let beacon := calldataload(sub(codesize(), add(metadataLength, 0x20)))

            // Fetch implementation address from the beacon
            mstore(0x40, 0x5c60da1b00000000000000000000000000000000000000000000000000000000)
            let result := staticcall(gas(), beacon, 0x40, 4, 0x40, 32)
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            let implementation := mload(0x40)

            // delegatecall to the implementation
            calldatacopy(0, 0, calldatasize())
            codecopy(calldatasize(), sub(codesize(), metadataLength), metadataLength)
            result := delegatecall(gas(), implementation, 0, add(metadataLength, calldatasize()), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}