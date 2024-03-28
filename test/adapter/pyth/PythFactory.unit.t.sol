// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {PythOracleHelper} from "test/adapter/pyth/PythOracleHelper.sol";
import {arrOf, boundAddr, distinct} from "test/utils/TestUtils.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";
import {PythFactory} from "src/adapter/pyth/PythFactory.sol";
import {Errors} from "src/lib/Errors.sol";
import {FeedIdentifierLib} from "src/lib/FeedIdentifier.sol";

contract PythFactoryPropTest is PythOracleHelper {
    address GOVERNOR = makeAddr("GOVERNOR");
    PythFactory factory;

    function test_Deploy_Identity(FuzzableState memory s) public {
        setUpState(s);
        factory = new PythFactory(GOVERNOR, PYTH);

        vm.prank(GOVERNOR);
        factory.govSetFeeds(arrOf(s.base), arrOf(s.quote), arrOf(FeedIdentifierLib.fromBytes32(s.feedId)));

        address deployedOracle = factory.deploy(s.base, s.quote, abi.encode(s.maxStaleness));
        assertEq(deployedOracle.codehash, oracle.codehash);
    }

    function test_Deploy_RevertsWhen_NoFeed(address base, address quote, uint256 maxStaleness) public {
        factory = new PythFactory(GOVERNOR, PYTH);
        vm.expectRevert(abi.encodeWithSelector(Errors.OracleFactory_NoFeed.selector, base, quote));
        factory.deploy(base, quote, abi.encode(maxStaleness));
    }
}
