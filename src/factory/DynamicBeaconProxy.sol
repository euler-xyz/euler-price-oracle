// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

contract DynamicBeaconProxy {
    // ERC-1967 beacon address slot. bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)
    bytes32 constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    bytes32 private constant _GENESIS_EVENT_SIGNATURE =
        0x6bf6eaff5e9af8fbccb949f4c38cc016936f8775363ccf4224db160365785d52;

    event Genesis();

    constructor(bytes memory trailingData) payable {
        assembly {
            log1(0, 0, _GENESIS_EVENT_SIGNATURE)
            sstore(_BEACON_SLOT, caller())

            let runtimesize := 3
            let tdsize := mload(trailingData)
            let ptr

            // copy runtime code to memory
            // codecopy(ptr, 0x00, runtimesize)
            mstore(0x00, 0x5f5ff30000000000000000000000000000000000000000000000000000000000)
            // mstore(0x00, 0x6080604052386020808203600039600051602060608284030360003960005163)
            // mstore(0x20, 0x5c60da1b6016526020600060046016845afa80603f573d6000803e3d6000fd5b)
            // mstore(0x40, 0x60005136600080378384860336396000803686016000845af491503d6000803e)
            // mstore(0x60, 0x816068573d6000fd5b3d6000f300000000000000000000000000000000000000)
            ptr := add(ptr, runtimesize)

            // store immutable beacon
            mstore(ptr, caller())
            ptr := add(ptr, 0x20)

            // store immutable `trailingData`
            codecopy(ptr, sub(codesize(), add(tdsize, 0x20)), codesize())
            ptr := add(ptr, add(tdsize, 0x20))

            // append `trailingData.length` for ERC-3448 compatibility
            mstore(ptr, tdsize)
            ptr := add(ptr, 0x20)

            // return the runtime code + immutable metadata
            let totalsize := add(add(runtimesize, tdsize), 0x60)
            return(0, totalsize)
        }
    }

    fallback() external payable {
        // assembly {
        //     let size := codesize()

        //     codecopy(0x00, sub(size, 0x20), 0x20)
        //     let trailingDataLength := mload(0x00)

        //     codecopy(0x00, sub(sub(size, trailingDataLength), 0x60), 0x20)
        //     let beacon := mload(0x00)

        //     mstore(0x00, 0x5c60da1b00000000000000000000000000000000000000000000000000000000) // mem[0x16:0x20] = sig:"implementation()"
        //     let result := staticcall(gas(), beacon, 0, 4, 0, 32) // mem[0x00:0x20] = implementation
        //     if iszero(result) {
        //         returndatacopy(0x00, 0x00, returndatasize())
        //         revert(0x00, returndatasize())
        //     }
        //     let implementation := mload(0x00)

        //     // delegatecall to the implementation
        //     calldatacopy(0x00, 0x00, calldatasize()) // mem[0x00:cds] = calldata
        //     codecopy(calldatasize(), sub(size, trailingDataLength), trailingDataLength) // mem[cds:cds+trailingDataLength] = trailingData

        //     result := delegatecall(gas(), implementation, 0, add(trailingDataLength, calldatasize()), 0, 0)
        //     returndatacopy(0, 0, returndatasize())
        //     if iszero(result) { revert(0, returndatasize()) }
        //     return(0, returndatasize())
        // }
    }
}
