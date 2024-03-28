// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {FeedIdentifierHarness} from "test/lib/FeedIdentifierHarness.sol";
import {Errors} from "src/lib/Errors.sol";
import {FeedIdentifier} from "src/lib/FeedIdentifier.sol";

contract FeedIdentifierTest is Test {
    FeedIdentifierHarness h;

    function setUp() public {
        h = new FeedIdentifierHarness();
    }

    function test_Cast_Bytes32(bytes32 id) public view {
        bytes32 $id = h.toBytes32(h.fromBytes32(id));
        assertEq($id, id);
    }

    function test_Cast_Address(address id) public view {
        address $id = h.toAddress(h.fromAddress(id));
        assertEq($id, id);
    }

    function test_ToAddress_RevertsWhen_Overflow(uint256 id) public {
        id = bound(id, uint256(type(uint160).max) + 1, type(uint256).max);

        vm.expectRevert(Errors.FeedIdentifier_ValueOOB.selector);
        h.toAddress(FeedIdentifier.wrap(bytes32(id)));
    }
}
