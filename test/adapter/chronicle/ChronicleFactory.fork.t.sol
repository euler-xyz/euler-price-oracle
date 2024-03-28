// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {CHRONICLE_ETH_USD_FEED} from "test/adapter/chronicle/ChronicleAddresses.sol";
import {WETH, USDC} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {arrOf} from "test/utils/TestUtils.sol";
import {ChronicleOracle} from "src/adapter/chronicle/ChronicleOracle.sol";
import {ChronicleFactory} from "src/adapter/chronicle/ChronicleFactory.sol";
import {FeedIdentifierLib} from "src/lib/FeedIdentifier.sol";

contract ChronicleFactoryForkTest is ForkTest {
    address GOVERNOR = makeAddr("GOVERNOR");
    address DEPLOYER = makeAddr("DEPLOYER");
    ChronicleFactory factory;

    function setUp() public {
        _setUpFork(19474200);
        factory = new ChronicleFactory(GOVERNOR);

        vm.store(
            CHRONICLE_ETH_USD_FEED,
            keccak256(abi.encode(0x104fBc016F4bb334D775a19E8A6510109AC63E00, uint256(2))),
            bytes32(uint256(1))
        );
    }

    function test_deploy() public {
        vm.prank(GOVERNOR);
        factory.govSetFeeds(arrOf(WETH), arrOf(USDC), arrOf(FeedIdentifierLib.fromAddress(CHRONICLE_ETH_USD_FEED)));

        vm.prank(DEPLOYER);
        ChronicleOracle oracle = ChronicleOracle(factory.deploy(WETH, USDC, abi.encode(24 hours)));

        assertApproxEqRel(oracle.getQuote(1e18, WETH, USDC), 3100e6, 0.1e18);
    }
}
