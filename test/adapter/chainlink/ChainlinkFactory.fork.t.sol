// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {CHAINLINK_ETH_USD_FEED} from "test/adapter/chainlink/ChainlinkAddresses.sol";
import {WETH, USDC} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {arrOf} from "test/utils/TestUtils.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";
import {ChainlinkFactory} from "src/adapter/chainlink/ChainlinkFactory.sol";
import {FeedIdentifierLib} from "src/lib/FeedIdentifier.sol";

contract ChainlinkFactoryForkTest is ForkTest {
    address GOVERNOR = makeAddr("GOVERNOR");
    address DEPLOYER = makeAddr("DEPLOYER");
    ChainlinkFactory factory;

    function setUp() public {
        _setUpFork(18888888);
        factory = new ChainlinkFactory(GOVERNOR);
    }

    function test_deploy() public {
        vm.prank(GOVERNOR);
        factory.govSetFeeds(arrOf(WETH), arrOf(USDC), arrOf(FeedIdentifierLib.fromAddress(CHAINLINK_ETH_USD_FEED)));

        vm.prank(DEPLOYER);
        ChainlinkOracle oracle = ChainlinkOracle(factory.deploy(WETH, USDC, abi.encode(24 hours)));

        assertApproxEqRel(oracle.getQuote(1e18, WETH, USDC), 2500e6, 0.1e18);
    }
}
