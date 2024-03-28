// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FeedIdentifierLib, FeedIdentifier} from "src/lib/FeedIdentifier.sol";

contract FeedIdentifierHarness {
    function fromBytes32(bytes32 id) external pure returns (FeedIdentifier) {
        return FeedIdentifierLib.fromBytes32(id);
    }

    function toBytes32(FeedIdentifier id) external pure returns (bytes32) {
        return FeedIdentifierLib.toBytes32(id);
    }

    function fromAddress(address id) external pure returns (FeedIdentifier) {
        return FeedIdentifierLib.fromAddress(id);
    }

    function toAddress(FeedIdentifier id) external pure returns (address) {
        return FeedIdentifierLib.toAddress(id);
    }
}
