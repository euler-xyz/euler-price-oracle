// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {IPMarket} from "@pendle/core-v2/interfaces/IPMarket.sol";
import {IPPYLpOracle} from "@pendle/core-v2/interfaces/IPPYLpOracle.sol";
import {IStandardizedYield} from "@pendle/core-v2/interfaces/IStandardizedYield.sol";
import {IPYieldToken} from "@pendle/core-v2/interfaces/IPYieldToken.sol";
import {MarketState} from "@pendle/core-v2/core/Market/MarketMathCore.sol";
import {PendleUniversalOracle} from "src/adapter/pendle/PendleUniversalOracle.sol";

/// @dev Decimal-scaling tests on a fully mocked, expired market where the Pendle rate is deterministic
/// (1 PT = 1 asset). The SY, its underlying asset and the quote are given independent decimals so the scale
/// is checked against economic ground truth rather than the adapter's own formula. Runs without a fork.
contract PendleUniversalOracleDecimalScaleTest is Test {
    /// @dev 0.01%
    uint256 constant REL_PRECISION = 0.0001e18;
    uint32 constant TWAP_WINDOW = 900;

    struct FuzzableState {
        uint8 syDecimals;
        uint8 assetDecimals;
        uint8 quoteDecimals;
        uint256 priceRatio; // whole asset per whole SY, scaled by 1e18
        uint256 totalPt;
        uint256 totalSy;
        uint256 totalLp;
    }

    address pendleOracle = makeAddr("pendleOracle");
    address market = makeAddr("market");
    address sy = makeAddr("sy");
    address pt = makeAddr("pt");
    address yt = makeAddr("yt");
    address asset = makeAddr("asset");
    address quote = makeAddr("quote");

    /// @dev The SY exchange rate maps raw SY to raw asset, so it embeds the SY/asset decimal offset.
    function _exchangeRate(FuzzableState memory s) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDiv(s.priceRatio, 10 ** s.assetDecimals, 10 ** s.syDecimals);
    }

    function setUpState(FuzzableState memory s) internal returns (FuzzableState memory) {
        vm.warp(1e6);
        s.syDecimals = uint8(bound(s.syDecimals, 4, 18));
        s.assetDecimals = uint8(bound(s.assetDecimals, 4, 18));
        s.quoteDecimals = uint8(bound(s.quoteDecimals, 4, 18));
        s.priceRatio = bound(s.priceRatio, 0.5e18, 2e18);
        s.totalPt = bound(s.totalPt, 1e18, 1e24);
        s.totalSy = bound(s.totalSy, 1e18, 1e24);
        s.totalLp = bound(s.totalLp, 1e18, 1e24);

        uint256 rate = _exchangeRate(s);

        vm.mockCall(
            pendleOracle,
            abi.encodeWithSelector(IPPYLpOracle.getOracleState.selector, market, TWAP_WINDOW),
            abi.encode(false, uint16(0), true)
        );
        vm.mockCall(market, abi.encodeWithSelector(IPMarket.readTokens.selector), abi.encode(sy, pt, yt));
        vm.mockCall(market, abi.encodeWithSelector(IPMarket.expiry.selector), abi.encode(block.timestamp - 1));
        vm.mockCall(
            sy,
            abi.encodeWithSelector(IStandardizedYield.assetInfo.selector),
            abi.encode(uint8(0), asset, s.assetDecimals)
        );
        vm.mockCall(sy, abi.encodeWithSelector(IStandardizedYield.exchangeRate.selector), abi.encode(rate));
        vm.mockCall(yt, abi.encodeWithSelector(IPYieldToken.pyIndexStored.selector), abi.encode(rate));
        vm.mockCall(yt, abi.encodeWithSelector(IPYieldToken.doCacheIndexSameBlock.selector), abi.encode(false));
        vm.mockCall(yt, abi.encodeWithSelector(IPYieldToken.pyIndexLastUpdatedBlock.selector), abi.encode(uint256(0)));

        MarketState memory state;
        state.totalPt = int256(s.totalPt);
        state.totalSy = int256(s.totalSy);
        state.totalLp = int256(s.totalLp);
        state.expiry = block.timestamp - 1;
        vm.mockCall(market, abi.encodeWithSelector(IPMarket.readState.selector, address(0)), abi.encode(state));

        vm.mockCall(sy, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.syDecimals));
        vm.mockCall(pt, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.assetDecimals));
        vm.mockCall(market, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(uint8(18)));
        vm.mockCall(asset, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.assetDecimals));
        vm.mockCall(quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.quoteDecimals));
        return s;
    }

    /// @dev One whole PT redeems for one whole asset post-expiry, expressed in the quote's decimals.
    function test_Quote_PtToAsset_WholeUnitParity(FuzzableState memory s) public {
        s = setUpState(s);
        PendleUniversalOracle oracle = new PendleUniversalOracle(pendleOracle, market, pt, asset, TWAP_WINDOW);
        uint256 outAmount = oracle.getQuote(10 ** s.assetDecimals, pt, asset);
        assertApproxEqRel(outAmount, 10 ** s.assetDecimals, REL_PRECISION);
    }

    /// @dev PT->SY scales by the SY's decimals, not the PT's. One whole PT is worth 1/priceRatio whole SY.
    function test_Quote_PtToSy_ScalesWithSyDecimals(FuzzableState memory s) public {
        s = setUpState(s);
        PendleUniversalOracle oracle = new PendleUniversalOracle(pendleOracle, market, pt, sy, TWAP_WINDOW);
        uint256 outAmount = oracle.getQuote(10 ** s.assetDecimals, pt, sy);
        // One whole PT redeems for 10 ** assetDecimals raw asset units. Convert these to raw SY
        // using the actual mocked rate: priceRatio loses precision when SY has more decimals.
        uint256 expected = FixedPointMathLib.fullMulDiv(10 ** s.assetDecimals, 1e18, _exchangeRate(s));
        assertApproxEqRel(outAmount, expected, REL_PRECISION);
    }

    /// @dev Regression: the mocked raw exchange rate floors to 9999, not 10000.
    function test_Quote_PtToSy_QuantizedExchangeRate() public {
        test_Quote_PtToSy_ScalesWithSyDecimals(FuzzableState(18, 4, 18, 999999999999333334, 1e18, 1e18, 1e18));
    }

    /// @dev The whole LP supply prices to the pool's reserves (PT at par plus SY at the exchange rate),
    /// expressed in the quote's decimals; the LP token's own 18 decimals must not enter the scale.
    function test_Quote_LpToAsset_PricesReserves(FuzzableState memory s) public {
        s = setUpState(s);
        PendleUniversalOracle oracle = new PendleUniversalOracle(pendleOracle, market, market, quote, TWAP_WINDOW);
        uint256 rawReserves = s.totalPt + FixedPointMathLib.fullMulDiv(s.totalSy, _exchangeRate(s), 1e18);
        uint256 expected = FixedPointMathLib.fullMulDiv(rawReserves, 10 ** s.quoteDecimals, 10 ** s.assetDecimals);
        uint256 outAmount = oracle.getQuote(s.totalLp, market, quote);
        assertApproxEqRel(outAmount, expected, REL_PRECISION);
    }
}
