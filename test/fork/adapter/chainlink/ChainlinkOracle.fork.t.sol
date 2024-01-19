// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.23;

// import {ForkTest} from "test/utils/ForkTest.sol";
// import {
//     CHAINLINK_FEED_REGISTRY,
//     CHAINLINK_BTC_ETH_FEED,
//     CHAINLINK_USDC_ETH_FEED,
//     CHAINLINK_STETH_ETH_FEED,
//     WETH,
//     STETH,
//     WBTC,
//     USDC
// } from "test/utils/EthereumAddresses.sol";
// import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";

// contract ChainlinkOracleForkTest is ForkTest {
//     address internal GOVERNOR = makeAddr("GOVERNOR");

//     ChainlinkOracle oracle;

//     function setUp() public {
//         _setUpFork(18888888);
//         oracle = new ChainlinkOracle(CHAINLINK_FEED_REGISTRY, WETH);
//         oracle.initialize(GOVERNOR);

//         vm.prank(GOVERNOR);
//         oracle.govSetConfig(
//             ChainlinkOracle.ConfigParams({
//                 base: WBTC,
//                 quote: WETH,
//                 feed: CHAINLINK_BTC_ETH_FEED,
//                 maxStaleness: 8 * 60 * 60,
//                 maxDuration: 60,
//                 inverse: false
//             })
//         );

//         vm.prank(GOVERNOR);
//         oracle.govSetConfig(
//             ChainlinkOracle.ConfigParams({
//                 base: USDC,
//                 quote: WETH,
//                 feed: CHAINLINK_USDC_ETH_FEED,
//                 maxStaleness: 8 * 60 * 60,
//                 maxDuration: 60,
//                 inverse: false
//             })
//         );

//         vm.prank(GOVERNOR);
//         oracle.govSetConfig(
//             ChainlinkOracle.ConfigParams({
//                 base: STETH,
//                 quote: WETH,
//                 feed: CHAINLINK_STETH_ETH_FEED,
//                 maxStaleness: 24 * 60 * 60,
//                 maxDuration: 60,
//                 inverse: false
//             })
//         );
//     }

//     function test_btcEth() public {
//         uint256 unitPrice = 18.8484406456306085e18;
//         assertEq(oracle.getQuote(1, WBTC, WETH), unitPrice / 1e8);
//         assertEq(oracle.getQuote(1e2, WBTC, WETH), unitPrice / 1e6);
//         assertEq(oracle.getQuote(1e4, WBTC, WETH), unitPrice / 1e4);
//         assertEq(oracle.getQuote(1e6, WBTC, WETH), unitPrice / 1e2);
//         assertEq(oracle.getQuote(1e8, WBTC, WETH), unitPrice);
//         assertEq(oracle.getQuote(1e10, WBTC, WETH), unitPrice * 1e2);
//         assertEq(oracle.getQuote(1e12, WBTC, WETH), unitPrice * 1e4);
//         assertEq(oracle.getQuote(1e14, WBTC, WETH), unitPrice * 1e6);
//         assertEq(oracle.getQuote(1e16, WBTC, WETH), unitPrice * 1e8);
//     }

//     function test_btcEth_inverse() public {
//         uint256 unitPrice = 18.8484406456306085e18;
//         assertEq(oracle.getQuote(1, WETH, WBTC), 1e8 / unitPrice);
//         assertEq(oracle.getQuote(1e4, WETH, WBTC), 1e12 / unitPrice);
//         assertEq(oracle.getQuote(1e8, WETH, WBTC), 1e16 / unitPrice);
//         assertEq(oracle.getQuote(1e12, WETH, WBTC), 1e20 / unitPrice);
//         assertEq(oracle.getQuote(1e14, WETH, WBTC), 1e22 / unitPrice);
//         assertEq(oracle.getQuote(1e16, WETH, WBTC), 1e24 / unitPrice);
//         assertEq(oracle.getQuote(1e18, WETH, WBTC), 1e26 / unitPrice);
//         assertEq(oracle.getQuote(1e20, WETH, WBTC), 1e28 / unitPrice);
//         assertEq(oracle.getQuote(1e22, WETH, WBTC), 1e30 / unitPrice);
//         assertEq(oracle.getQuote(1e24, WETH, WBTC), 1e32 / unitPrice);
//     }

//     function test_usdcEth() public {
//         uint256 unitPrice = 0.000411801771748396e18;
//         assertEq(oracle.getQuote(1, USDC, WETH), unitPrice / 1e6);
//         assertEq(oracle.getQuote(1e2, USDC, WETH), unitPrice / 1e4);
//         assertEq(oracle.getQuote(1e4, USDC, WETH), unitPrice / 1e2);
//         assertEq(oracle.getQuote(1e6, USDC, WETH), unitPrice);
//         assertEq(oracle.getQuote(1e8, USDC, WETH), unitPrice * 1e2);
//         assertEq(oracle.getQuote(1e10, USDC, WETH), unitPrice * 1e4);
//         assertEq(oracle.getQuote(1e12, USDC, WETH), unitPrice * 1e6);
//         assertEq(oracle.getQuote(1e14, USDC, WETH), unitPrice * 1e8);
//         assertEq(oracle.getQuote(1e16, USDC, WETH), unitPrice * 1e10);
//         assertEq(oracle.getQuote(1e18, USDC, WETH), unitPrice * 1e12);
//         assertEq(oracle.getQuote(1e20, USDC, WETH), unitPrice * 1e14);
//     }

//     function test_usdcEth_inverse() public {
//         uint256 unitPrice = 0.000411801771748396e18;
//         assertEq(oracle.getQuote(1, WETH, USDC), 1e6 / unitPrice);
//         assertEq(oracle.getQuote(1e4, WETH, USDC), 1e10 / unitPrice);
//         assertEq(oracle.getQuote(1e8, WETH, USDC), 1e14 / unitPrice);
//         assertEq(oracle.getQuote(1e12, WETH, USDC), 1e18 / unitPrice);
//         assertEq(oracle.getQuote(1e14, WETH, USDC), 1e20 / unitPrice);
//         assertEq(oracle.getQuote(1e16, WETH, USDC), 1e22 / unitPrice);
//         assertEq(oracle.getQuote(1e18, WETH, USDC), 1e24 / unitPrice);
//         assertEq(oracle.getQuote(1e20, WETH, USDC), 1e26 / unitPrice);
//         assertEq(oracle.getQuote(1e22, WETH, USDC), 1e28 / unitPrice);
//         assertEq(oracle.getQuote(1e24, WETH, USDC), 1e30 / unitPrice);
//     }

//     function test_stEthEth() public {
//         uint256 unitPrice = 0.9989827361604893e18;
//         assertEq(oracle.getQuote(1, STETH, WETH), unitPrice / 1e18);
//         assertEq(oracle.getQuote(1e4, STETH, WETH), unitPrice / 1e14);
//         assertEq(oracle.getQuote(1e8, STETH, WETH), unitPrice / 1e10);
//         assertEq(oracle.getQuote(1e12, STETH, WETH), unitPrice / 1e6);
//         assertEq(oracle.getQuote(1e14, STETH, WETH), unitPrice / 1e4);
//         assertEq(oracle.getQuote(1e16, STETH, WETH), unitPrice / 1e2);
//         assertEq(oracle.getQuote(1e18, STETH, WETH), unitPrice);
//         assertEq(oracle.getQuote(1e20, STETH, WETH), unitPrice * 1e2);
//         assertEq(oracle.getQuote(1e22, STETH, WETH), unitPrice * 1e4);
//         assertEq(oracle.getQuote(1e24, STETH, WETH), unitPrice * 1e6);
//     }

//     function test_stEthEth_inverse() public {
//         uint256 unitPrice = 0.9989827361604893e18;
//         assertEq(oracle.getQuote(1, WETH, STETH), unitPrice / 1e18);
//         assertEq(oracle.getQuote(1e4, WETH, STETH), unitPrice / 1e14);
//         assertEq(oracle.getQuote(1e8, WETH, STETH), unitPrice / 1e10);
//         assertEq(oracle.getQuote(1e12, WETH, STETH), unitPrice / 1e6);
//         assertEq(oracle.getQuote(1e14, WETH, STETH), unitPrice / 1e4);
//         assertEq(oracle.getQuote(1e16, WETH, STETH), unitPrice / 1e2);
//         assertEq(oracle.getQuote(1e18, WETH, STETH), unitPrice);
//         assertEq(oracle.getQuote(1e20, WETH, STETH), unitPrice * 1e2);
//         assertEq(oracle.getQuote(1e22, WETH, STETH), unitPrice * 1e4);
//         assertEq(oracle.getQuote(1e24, WETH, STETH), unitPrice * 1e6);
//     }
// }
