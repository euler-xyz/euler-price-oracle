// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.22;

contract MetaBeaconProxy {
    // ERC-1967 beacon address slot. bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)
    bytes32 constant BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;
    // Beacon implementation() selector
    bytes32 constant IMPLEMENTATION_SELECTOR = 0x5c60da1b00000000000000000000000000000000000000000000000000000000;

    bool initialized;

    event Genesis();

    error AlreadyInitialized();

    // The proxy will be deployed with custom deployment code, therefore solidity constructor is not available
    function initialize() public {
        if (initialized) revert AlreadyInitialized();
        initialized = true;

        // Store the beacon address in ERC-1967 slot for compatibility with block explorers
        assembly {
            sstore(BEACON_SLOT, caller())
        }

        emit Genesis();
    }

    fallback() external {
        // TODO pack meta size and beacon addr?
        assembly {
            let beacon, metadataSize

            // load beacon and meta data length from code

            codecopy(0, sub(codesize(), 64), 64)
            metadataSize := mload(0)
            beacon := mload(32)

            // fetch implementation address from the beacon

            mstore(0, IMPLEMENTATION_SELECTOR) // implementation() selector
            let result := staticcall(gas(), beacon, 0, 4, 0, 32)
            if iszero(result) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
            let implementation := mload(0)

            // delegate call to the implementation

            calldatacopy(0, 0, calldatasize())
            // attach metadata
            codecopy(calldatasize(), sub(codesize(), add(metadataSize, 64)), metadataSize)
            // attach length of metadata
            mstore(add(calldatasize(), metadataSize), metadataSize)
            result := delegatecall(gas(), implementation, 0, add(add(calldatasize(), metadataSize), 32), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}
