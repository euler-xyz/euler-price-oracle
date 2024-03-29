// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Errors} from "src/lib/Errors.sol";

/// @notice Custom type wrapping address or bytes32 identifiers.
type FeedIdentifier is bytes32;

using FeedIdentifierLib for FeedIdentifier global;

/// @title FeedIdentifierLib
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Utilities for wrapping address or bytes32 identifiers.
library FeedIdentifierLib {
    /// @notice Cast `FeedIdentifier` to `bytes32`.
    /// @param id The identifier.
    /// @return `FeedIdentifier` cast to `bytes32`.
    function toBytes32(FeedIdentifier id) internal pure returns (bytes32) {
        return FeedIdentifier.unwrap(id);
    }

    /// @notice Cast `FeedIdentifier` to `address`.
    /// @param id The identifier.
    /// @return `FeedIdentifier` cast to `address`.
    function toAddress(FeedIdentifier id) internal pure returns (address) {
        if (uint256(FeedIdentifier.unwrap(id)) > type(uint160).max) revert Errors.FeedIdentifier_ValueOOB();
        return address(uint160(uint256((FeedIdentifier.unwrap(id)))));
    }

    /// @notice Cast `bytes32` to `FeedIdentifier`.
    /// @param id The identifier.
    /// @return `bytes32` cast to `FeedIdentifier`.
    function fromBytes32(bytes32 id) internal pure returns (FeedIdentifier) {
        return FeedIdentifier.wrap(id);
    }

    /// @notice Cast `address` to `FeedIdentifier`.
    /// @param id The identifier.
    /// @return `address` cast to `FeedIdentifier`.
    function fromAddress(address id) internal pure returns (FeedIdentifier) {
        return FeedIdentifier.wrap(bytes32(uint256(uint160(id))));
    }
}
