// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {FeedIdentifierLib, FeedIdentifier} from "src/lib/FeedIdentifier.sol";

contract FeedIdentifierTest is Test {
    function test_Cast_Bytes32(bytes32 id) public pure {
        bytes32 $id = FeedIdentifierLib.fromBytes32(id).toBytes32();
        assertEq($id, id);
    }

    function test_Cast_Address(address id) public pure {
        address $id = FeedIdentifierLib.fromAddress(id).toAddress();
        assertEq($id, id);
    }

    function test_NoCollision(address id) public pure {
        address $id = FeedIdentifierLib.fromAddress(id).toAddress();
        assertEq($id, id);
    }
}
