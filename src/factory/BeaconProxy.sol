// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

contract BeaconProxy {
    // ERC-1967 beacon address slot. bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)
    bytes32 constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
    // Beacon implementation() selector
    bytes32 constant IMPLEMENTATION_SELECTOR = 0x5c60da1b00000000000000000000000000000000000000000000000000000000;

    address immutable beacon;
    uint256 immutable metadataLength;
    bytes32 immutable metadata0;
    bytes32 immutable metadata1;
    bytes32 immutable metadata2;
    bytes32 immutable metadata3;
    bytes32 immutable metadata4;
    bytes32 immutable metadata5;
    bytes32 immutable metadata6;
    bytes32 immutable metadata7;

    event Genesis();

    constructor(bytes memory trailingData) {
        emit Genesis();

        // 4 immutable slots, minus 32 bytes for the ERC-3448 length
        require(trailingData.length <= (8 * 32) - 32, "trailing data too long");

        // Beacon is always the proxy creator; store it in immutable
        beacon = msg.sender;

        // Store the beacon address in ERC-1967 slot for compatibility with block explorers
        assembly {
            sstore(BEACON_SLOT, caller())
        }

        // Append the size of the trailing data for ERC-3448 compatibility
        trailingData = abi.encodePacked(trailingData, trailingData.length);

        metadataLength = trailingData.length;

        // Further pad length with uninitialised memory so the decode will succeed
        assembly {
            mstore(trailingData, 256)
        }
        (metadata0, metadata1, metadata2, metadata3, metadata4, metadata5, metadata6, metadata7) = abi.decode(trailingData, (bytes32, bytes32, bytes32, bytes32, bytes32, bytes32, bytes32, bytes32));
    }

    fallback() external {
        address beacon_ = beacon;
        uint256 metadataLength_ = metadataLength;
        bytes32 metadata0_ = metadata0;
        bytes32 metadata1_ = metadata1;
        bytes32 metadata2_ = metadata2;
        bytes32 metadata3_ = metadata3;
        bytes32 metadata4_ = metadata4;
        bytes32 metadata5_ = metadata5;
        bytes32 metadata6_ = metadata6;
        bytes32 metadata7_ = metadata7;

        assembly {
            // Fetch implementation address from the beacon
            mstore(0, IMPLEMENTATION_SELECTOR)
            let result := staticcall(gas(), beacon_, 0, 4, 0, 32)
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            let implementation := mload(0)

            // delegatecall to the implementation
            calldatacopy(0, 0, calldatasize())
            mstore(calldatasize(), metadata0_)
            mstore(add(32, calldatasize()), metadata1_)
            mstore(add(64, calldatasize()), metadata2_)
            mstore(add(96, calldatasize()), metadata3_)
            mstore(add(128, calldatasize()), metadata4_)
            mstore(add(160, calldatasize()), metadata5_)
            mstore(add(192, calldatasize()), metadata6_)
            mstore(add(224, calldatasize()), metadata7_)
            result := delegatecall(gas(), implementation, 0, add(metadataLength_, calldatasize()), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
