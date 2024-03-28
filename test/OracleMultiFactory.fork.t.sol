// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {CHAINLINK_ETH_USD_FEED} from "test/adapter/chainlink/ChainlinkAddresses.sol";
import {CHRONICLE_ETH_USD_FEED} from "test/adapter/chronicle/ChronicleAddresses.sol";
import {PYTH, PYTH_ETH_USD_FEED} from "test/adapter/pyth/PythFeeds.sol";
import {REDSTONE_ETH_USD_FEED} from "test/adapter/redstone/RedstoneFeeds.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {arrOf} from "test/utils/TestUtils.sol";
import {WETH, USD} from "test/utils/EthereumAddresses.sol";
import {OracleMultiFactory} from "src/OracleMultiFactory.sol";
import {ChainlinkFactory} from "src/adapter/chainlink/ChainlinkFactory.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";
import {ChronicleFactory} from "src/adapter/chronicle/ChronicleFactory.sol";
import {ChronicleOracle} from "src/adapter/chronicle/ChronicleOracle.sol";
import {PythFactory} from "src/adapter/pyth/PythFactory.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";
import {RedstoneCoreFactory} from "src/adapter/redstone/RedstoneCoreFactory.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";
import {FeedIdentifierLib} from "src/lib/FeedIdentifier.sol";

contract OracleMultiFactoryForkTest is ForkTest {
    address GOVERNOR = makeAddr("GOVERNOR");
    OracleMultiFactory multiFactory;

    function setUp() public {
        _setUpFork(19533648);
        multiFactory = new OracleMultiFactory(GOVERNOR);
    }

    function test_AllFactories() public {
        vm.startPrank(GOVERNOR);
        ChainlinkFactory chainlinkFactory = new ChainlinkFactory(GOVERNOR);
        ChronicleFactory chronicleFactory = new ChronicleFactory(GOVERNOR);
        PythFactory pythFactory = new PythFactory(GOVERNOR, PYTH);
        RedstoneCoreFactory redstoneCoreFactory = new RedstoneCoreFactory(GOVERNOR);

        chainlinkFactory.govSetFeeds(
            arrOf(WETH), arrOf(USD), arrOf(FeedIdentifierLib.fromAddress(CHAINLINK_ETH_USD_FEED))
        );
        chronicleFactory.govSetFeeds(
            arrOf(WETH), arrOf(USD), arrOf(FeedIdentifierLib.fromAddress(CHRONICLE_ETH_USD_FEED))
        );
        pythFactory.govSetFeeds(arrOf(WETH), arrOf(USD), arrOf(FeedIdentifierLib.fromBytes32(PYTH_ETH_USD_FEED)));
        redstoneCoreFactory.govSetFeeds(
            arrOf(WETH), arrOf(USD), arrOf(FeedIdentifierLib.fromBytes32(REDSTONE_ETH_USD_FEED))
        );

        multiFactory.setFactoryStatus(address(chainlinkFactory), true);
        multiFactory.setFactoryStatus(address(chronicleFactory), true);
        multiFactory.setFactoryStatus(address(pythFactory), true);
        multiFactory.setFactoryStatus(address(redstoneCoreFactory), true);

        ChainlinkOracle chainlinkOracle =
            ChainlinkOracle(multiFactory.deployWithFactory(address(chainlinkFactory), WETH, USD, abi.encode(24 hours)));
        ChronicleOracle chronicleOracle =
            ChronicleOracle(multiFactory.deployWithFactory(address(chronicleFactory), WETH, USD, abi.encode(24 hours)));
        PythOracle pythOracle =
            PythOracle(multiFactory.deployWithFactory(address(pythFactory), WETH, USD, abi.encode(365 days)));
        RedstoneCoreOracle redstoneCoreOracle = RedstoneCoreOracle(
            multiFactory.deployWithFactory(address(redstoneCoreFactory), WETH, USD, abi.encode(3 minutes))
        );
    }
}
