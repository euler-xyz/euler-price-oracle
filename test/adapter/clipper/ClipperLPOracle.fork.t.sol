// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {CLIPPER_LP} from "test/adapter/clipper/ClipperAddresses.sol";
import {
    CHAINLINK_DAI_USD_FEED,
    CHAINLINK_USDC_USD_FEED,
    CHAINLINK_USDT_USD_FEED,
    CHAINLINK_BTC_USD_FEED,
    CHAINLINK_ETH_USD_FEED
} from "test/adapter/chainlink/ChainlinkAddresses.sol";
import {DAI, USD, USDC, USDT, WBTC, WETH} from "test/utils/EthereumAddresses.sol";
import {ForkTest} from "test/utils/ForkTest.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";
import {ClipperLPOracle} from "src/adapter/clipper/ClipperLPOracle.sol";
import {EulerRouter} from "src/EulerRouter.sol";

contract ClipperLPOracleForkTest is ForkTest {
    address EVC = makeAddr("EVC");
    address GOVERNOR = makeAddr("GOVERNOR");
    EulerRouter router;

    function setUp() public {
        _setUpFork(21140538);

        router = new EulerRouter(EVC, GOVERNOR);
        vm.startPrank(GOVERNOR);
        router.govSetConfig(DAI, USD, address(new ChainlinkOracle(DAI, USD, CHAINLINK_DAI_USD_FEED, 72 hours)));
        router.govSetConfig(USDC, USD, address(new ChainlinkOracle(USDC, USD, CHAINLINK_USDC_USD_FEED, 72 hours)));
        router.govSetConfig(USDT, USD, address(new ChainlinkOracle(USDT, USD, CHAINLINK_USDT_USD_FEED, 72 hours)));
        router.govSetConfig(WBTC, USD, address(new ChainlinkOracle(WBTC, USD, CHAINLINK_BTC_USD_FEED, 72 hours)));
        router.govSetConfig(WETH, USD, address(new ChainlinkOracle(WETH, USD, CHAINLINK_ETH_USD_FEED, 72 hours)));
        vm.stopPrank();
    }

    function test_Constructor_Integrity() public {
        ClipperLPOracle oracle = new ClipperLPOracle(CLIPPER_LP, USD, address(router));
        assertEq(oracle.lpToken(), CLIPPER_LP);
        assertEq(oracle.quote(), USD);
        assertEq(oracle.oracle(), address(router));
    }

    function test_GetQuote_Integrity() public {
        ClipperLPOracle oracle = new ClipperLPOracle(CLIPPER_LP, USD, address(router));

        uint256 outAmount = oracle.getQuote(1e18, CLIPPER_LP, USD);
        uint256 outAmount1000 = oracle.getQuote(1000e18, CLIPPER_LP, USD);
        assertApproxEqRel(outAmount, 1.65e18, 0.05e18);
        assertApproxEqAbs(outAmount1000, outAmount * 1000, 1000);


        uint256 outAmountInv = oracle.getQuote(outAmount, USD, CLIPPER_LP);
        assertApproxEqAbs(outAmountInv, 1e18, 1);
        uint256 outAmountInv1000 = oracle.getQuote(outAmount1000, USD, CLIPPER_LP);
        assertApproxEqAbs(outAmountInv1000, 1000e18, 1000);
    }
}
