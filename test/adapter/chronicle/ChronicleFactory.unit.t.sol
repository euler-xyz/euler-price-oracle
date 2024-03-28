// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {ChronicleOracleHelper} from "test/adapter/chronicle/ChronicleOracleHelper.sol";
import {arrOf, boundAddr, distinct} from "test/utils/TestUtils.sol";
import {ChronicleOracle} from "src/adapter/chronicle/ChronicleOracle.sol";
import {ChronicleFactory} from "src/adapter/chronicle/ChronicleFactory.sol";
import {FeedIdentifierLib} from "src/lib/FeedIdentifier.sol";

contract ChronicleFactoryPropTest is ChronicleOracleHelper {
    address GOVERNOR = makeAddr("GOVERNOR");
    ChronicleFactory factory;

    function setUp() public {
        factory = new ChronicleFactory(GOVERNOR);
    }

    function test_Deploy_Identity(FuzzableState memory s) public {
        setUpState(s);

        vm.prank(GOVERNOR);
        factory.govSetFeeds(arrOf(s.base), arrOf(s.quote), arrOf(FeedIdentifierLib.fromAddress(s.feed)));

        address deployedOracle = factory.deploy(s.base, s.quote, abi.encode(s.maxStaleness));
        assertEq(deployedOracle.codehash, oracle.codehash);
    }
}
