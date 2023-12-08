// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Script} from "forge-std/Script.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";
import {GovernedUniswapV3Oracle} from "src/adapter/uniswap/GovernedUniswapV3Oracle.sol";
import {OracleFactory} from "src/factory/OracleFactory.sol";
import {ImmutableLinearStrategy} from "src/strategy/linear/ImmutableLinearStrategy.sol";
import {
    CHAINLINK_FEED_REGISTRY,
    CHAINLINK_USDC_ETH_FEED,
    UNISWAP_V3_FACTORY,
    UNISWAP_V3_USDC_WETH_500,
    USDC,
    WETH
} from "test/utils/EthereumAddresses.sol";

contract DeployScript is Script {
    address private constant UPGRADE_ADMIN = address(0x271828);

    function run() external {
        // Deploy Chainlink oracle
        OracleFactory chainlinkFactory = new OracleFactory(address(this));
        ChainlinkOracle chainlinkOracleImpl = new ChainlinkOracle(CHAINLINK_FEED_REGISTRY, WETH);
        chainlinkFactory.setImplementation(address(chainlinkOracleImpl));
        ChainlinkOracle chainlinkOracle = ChainlinkOracle(chainlinkFactory.deploy(true, ""));

        // Deploy UniV3 oracle
        OracleFactory univ3Factory = new OracleFactory(address(this));
        GovernedUniswapV3Oracle univ3OracleImpl = new GovernedUniswapV3Oracle(UNISWAP_V3_FACTORY);
        univ3Factory.setImplementation(address(univ3OracleImpl));
        GovernedUniswapV3Oracle univ3Oracle = GovernedUniswapV3Oracle(univ3Factory.deploy(true, ""));

        // Deploy Linear strategy (try chainlink, fall back to univ3)
        OracleFactory linearFactory = new OracleFactory(address(this));
        ImmutableLinearStrategy linearImpl = new ImmutableLinearStrategy();
        linearFactory.setImplementation(address(linearImpl));
        ImmutableLinearStrategy linearStrategy = ImmutableLinearStrategy(
            linearFactory.deploy(true, abi.encodePacked(address(chainlinkOracle), address(univ3Oracle)))
        );

        chainlinkOracle.govSetConfig(
            ChainlinkOracle.ConfigParams({
                base: USDC,
                quote: WETH,
                feed: CHAINLINK_USDC_ETH_FEED,
                maxStaleness: 24 hours,
                maxDuration: 15 minutes,
                inverse: false
            })
        );

        univ3Oracle.govSetConfig(UNISWAP_V3_USDC_WETH_500, 15 minutes);
    }
}
