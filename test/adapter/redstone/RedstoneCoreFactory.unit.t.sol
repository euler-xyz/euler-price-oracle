// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {RedstoneCoreOracleHelper} from "test/adapter/redstone/RedstoneCoreOracleHelper.sol";
import {arrOf, boundAddr, distinct} from "test/utils/TestUtils.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";
import {RedstoneCoreFactory} from "src/adapter/redstone/RedstoneCoreFactory.sol";
import {FeedIdentifierLib} from "src/lib/FeedIdentifier.sol";

contract RedstoneCoreFactoryPropTest is RedstoneCoreOracleHelper {
    address GOVERNOR = makeAddr("GOVERNOR");
    RedstoneCoreFactory factory;

    function setUp() public {
        factory = new RedstoneCoreFactory(GOVERNOR);
    }

    function test_Deploy_Identity(FuzzableState memory s) public {
        setUpState(s);

        vm.prank(GOVERNOR);
        factory.govSetFeeds(arrOf(s.base), arrOf(s.quote), arrOf(FeedIdentifierLib.fromBytes32(s.feedId)));

        address _oracle = address(new RedstoneCoreOracle(s.base, s.quote, s.feedId, s.maxStaleness));
        address deployedOracle = factory.deploy(s.base, s.quote, abi.encode(s.maxStaleness));
        assertEq(deployedOracle.codehash, _oracle.codehash);
    }
}
