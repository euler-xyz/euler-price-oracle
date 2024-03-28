// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {PYTH, PYTH_ETH_USD_FEED} from "test/adapter/pyth/PythFeeds.sol";
import {WETH, USDC} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {arrOf} from "test/utils/TestUtils.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";
import {PythFactory} from "src/adapter/pyth/PythFactory.sol";
import {FeedIdentifierLib} from "src/lib/FeedIdentifier.sol";

contract PythFactoryForkTest is ForkTest {
    address GOVERNOR = makeAddr("GOVERNOR");
    address DEPLOYER = makeAddr("DEPLOYER");
    PythFactory factory;

    function setUp() public {
        _setUpFork(19000000);
        factory = new PythFactory(GOVERNOR, PYTH);
    }

    function test_deploy() public {
        vm.prank(GOVERNOR);
        factory.govSetFeeds(arrOf(WETH), arrOf(USDC), arrOf(FeedIdentifierLib.fromBytes32(PYTH_ETH_USD_FEED)));

        vm.prank(DEPLOYER);
        PythOracle oracle = PythOracle(factory.deploy(WETH, USDC, abi.encode(365 days)));

        assertApproxEqRel(oracle.getQuote(1e18, WETH, USDC), 2500e6, 0.1e18);
    }
}
