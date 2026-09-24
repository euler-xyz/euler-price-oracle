// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPMarket} from "@pendle/core-v2/interfaces/IPMarket.sol";
import {IPPYLpOracle} from "@pendle/core-v2/interfaces/IPPYLpOracle.sol";
import {IPPrincipalToken} from "@pendle/core-v2/interfaces/IPPrincipalToken.sol";
import {IStandardizedYield} from "@pendle/core-v2/interfaces/IStandardizedYield.sol";
import {PendleUniversalOracle} from "src/adapter/pendle/PendleUniversalOracle.sol";

/// @dev Decimal-scaling fork tests on a market whose reported decimals diverge, exercising two paths
/// that no other fixture covers:
///   1. finding #605 - LP-mode pricing for a sub-18-decimal asset. The Pendle LP rate is a
///      raw-asset-per-raw-LP ratio (x1e18), so the base must be scaled against the asset's decimals,
///      not the LP token's fixed 18.
///   2. the adjacent PT->SY case - a Pendle PT tracks its ASSET's decimals, not its SY's, and the two
///      can differ. The base must be scaled against the rate's denomination unit (SY decimals here),
///      not the PT's decimals.
/// The PT-mEDGE market is a single fixture exhibiting both: SY reports 18 decimals while the PT and the
/// underlying asset (USDC) report 6.
contract PendleUniversalOracleDecimalScaleForkTest is Test {
    address constant PENDLE_ORACLE = 0x9a9Fa8338dd5E5B2188006f1Cd2Ef26d921650C2;
    // PT-mEDGE market: SY-mEDGE reports 18 decimals, its underlying (USDC) and the PT report 6, LP reports 18.
    address constant MARKET_6DEC = 0xcBEeD3364912bCee868cfA9cff6Fe865C85eA094;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint32 constant TWAP = 900;

    function setUp() public {
        vm.createSelectFork(vm.envString("ETHEREUM_RPC_URL"), 25834000);
    }

    /// @dev The LP token reports 18 decimals but the underlying asset has 6.
    function test_lpMode_6DecimalAsset_baseTokenDecimalsMismatch() public view {
        assertEq(IERC20(MARKET_6DEC).decimals(), 18, "LP token reports 18 decimals");
        (IStandardizedYield sy,,) = IPMarket(MARKET_6DEC).readTokens();
        (,, uint8 assetDecimals) = sy.assetInfo();
        assertEq(assetDecimals, 6, "SY asset has 6 decimals");
    }

    /// @dev getQuote(1e18 LP) must equal the raw-per-raw Pendle rate, not rate / 10^(18-6).
    function test_lpMode_6DecimalAsset_quoteMatchesRawRate() public {
        PendleUniversalOracle oracle =
            new PendleUniversalOracle(PENDLE_ORACLE, MARKET_6DEC, MARKET_6DEC, USDC, TWAP);
        uint256 rate = IPPYLpOracle(PENDLE_ORACLE).getLpToAssetRate(MARKET_6DEC, TWAP);
        uint256 got = oracle.getQuote(1e18, MARKET_6DEC, USDC);
        // Pre-fix this returned rate / 1e12. After the fix it returns the raw-per-raw rate.
        assertApproxEqRel(got, rate, 0.001e18, "LP quote must equal raw Pendle rate");
    }

    /// @dev Independent proof the rate is a raw-unit ratio: implied total asset value from
    /// totalSupply * rate / 1e18 must match the market's own SY+PT reserves.
    function test_lpMode_rateIsRawUnitRatio() public view {
        uint256 rate = IPPYLpOracle(PENDLE_ORACLE).getLpToAssetRate(MARKET_6DEC, TWAP);
        uint256 lpSupply = IERC20(MARKET_6DEC).totalSupply();
        (IStandardizedYield sy, IPPrincipalToken pt,) = IPMarket(MARKET_6DEC).readTokens();
        uint256 syAsset = IERC20(address(sy)).balanceOf(MARKET_6DEC) * sy.exchangeRate() / 1e18;
        uint256 actual = syAsset + IERC20(address(pt)).balanceOf(MARKET_6DEC);
        uint256 implied = lpSupply * rate / 1e18;
        assertApproxEqRel(implied, actual, 0.03e18, "LP rate is denominated in raw units");
    }

    /// @dev SY-mEDGE reports 18 decimals while its asset and the PT report 6 - so a Pendle PT does NOT
    /// share its SY's decimals; it tracks the asset's. PT->SY must scale the base against the SY's
    /// decimals, not the PT's, or the quote is over-reported by 10^(18-6).
    function test_ptToSy_baseFollowsSyDecimalsNotPtDecimals() public {
        (IStandardizedYield sy, IPPrincipalToken pt,) = IPMarket(MARKET_6DEC).readTokens();
        assertEq(IERC20(address(sy)).decimals(), 18, "SY reports 18 decimals");
        assertEq(IERC20(address(pt)).decimals(), 6, "PT reports 6 decimals");

        PendleUniversalOracle oracle =
            new PendleUniversalOracle(PENDLE_ORACLE, MARKET_6DEC, address(pt), address(sy), TWAP);
        uint256 rate = IPPYLpOracle(PENDLE_ORACLE).getPtToSyRate(MARKET_6DEC, TWAP);
        uint256 got = oracle.getQuote(1e6, address(pt), address(sy));
        // Correct raw consumption is rawSY = rawPT * rate / 1e18. Pre-fix this over-reported by 1e12.
        assertApproxEqRel(got, uint256(1e6) * rate / 1e18, 0.001e18, "PT->SY quote must follow raw-per-raw");

        uint256 back = oracle.getQuote(got, address(sy), address(pt));
        assertApproxEqRel(back, 1e6, 0.001e18, "PT->SY->PT round-trip");
    }

    /// @dev The SY-denominated value of 1 PT, converted to the asset via the SY exchange rate, must
    /// equal the direct PT->asset value - i.e. the PT->SY scaling is economically correct, not merely
    /// self-consistent with the rate formula.
    function test_ptToSy_economicallyConsistentWithPtToAsset() public {
        (IStandardizedYield sy, IPPrincipalToken pt,) = IPMarket(MARKET_6DEC).readTokens();
        PendleUniversalOracle ptSy =
            new PendleUniversalOracle(PENDLE_ORACLE, MARKET_6DEC, address(pt), address(sy), TWAP);
        PendleUniversalOracle ptAsset =
            new PendleUniversalOracle(PENDLE_ORACLE, MARKET_6DEC, address(pt), USDC, TWAP);

        uint256 rawSy = ptSy.getQuote(1e6, address(pt), address(sy));
        uint256 assetFromSy = rawSy * sy.exchangeRate() / 1e18; // SYUtils.syToAsset
        uint256 assetDirect = ptAsset.getQuote(1e6, address(pt), USDC);
        assertApproxEqRel(assetFromSy, assetDirect, 0.01e18, "PT->SY and PT->asset must agree in value");
    }
}
