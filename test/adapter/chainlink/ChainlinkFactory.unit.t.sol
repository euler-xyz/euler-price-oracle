// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {ChainlinkOracleHelper} from "test/adapter/chainlink/ChainlinkOracleHelper.sol";
import {arrOf, boundAddr, distinct} from "test/utils/TestUtils.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";
import {ChainlinkFactory} from "src/adapter/chainlink/ChainlinkFactory.sol";
import {Errors} from "src/lib/Errors.sol";
import {FeedIdentifierLib} from "src/lib/FeedIdentifier.sol";

contract ChainlinkFactoryPropTest is ChainlinkOracleHelper {
    address GOVERNOR = makeAddr("GOVERNOR");
    ChainlinkFactory factory;

    function setUp() public {
        factory = new ChainlinkFactory(GOVERNOR);
    }

    function test_Deploy_Identity(FuzzableState memory s) public {
        setUpState(s);

        vm.prank(GOVERNOR);
        factory.govSetFeeds(arrOf(s.base), arrOf(s.quote), arrOf(FeedIdentifierLib.fromAddress(s.feed)));

        address deployedOracle = factory.deploy(s.base, s.quote, abi.encode(s.maxStaleness));
        assertEq(deployedOracle.codehash, oracle.codehash);
    }

    function test_Deploy_RevertsWhen_NoFeed(address base, address quote, uint256 maxStaleness) public {
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        factory.deploy(base, quote, abi.encode(maxStaleness));
    }
}
