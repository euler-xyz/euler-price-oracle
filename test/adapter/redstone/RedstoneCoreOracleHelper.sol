// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {RedstoneCoreOracleHarness} from "test/adapter/redstone/RedstoneCoreOracleHarness.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";

contract RedstoneCoreOracleHelper is AdapterHelper {
    struct Bounds {
        uint8 minBaseDecimals;
        uint8 maxBaseDecimals;
        uint8 minQuoteDecimals;
        uint8 maxQuoteDecimals;
        uint8 minFeedDecimals;
        uint8 maxFeedDecimals;
        uint256 minInAmount;
        uint256 maxInAmount;
        uint256 minPrice;
        uint256 maxPrice;
    }

    Bounds internal DEFAULT_BOUNDS = Bounds({
        minBaseDecimals: 0,
        maxBaseDecimals: 18,
        minQuoteDecimals: 0,
        maxQuoteDecimals: 18,
        minFeedDecimals: 8,
        maxFeedDecimals: 18,
        minInAmount: 0,
        maxInAmount: type(uint128).max,
        minPrice: 1,
        maxPrice: 1e12 * 1e8
    });

    Bounds internal bounds = DEFAULT_BOUNDS;

    function setBounds(Bounds memory _bounds) internal {
        bounds = _bounds;
    }

    struct FuzzableState {
        // Config
        address base;
        address quote;
        bytes32 feedId;
        uint32 maxPriceStaleness;
        uint32 maxCacheStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        uint8 feedDecimals;
        // Answer
        uint256 price;
        // Environment
        uint256 tsDataPackage;
        uint256 tsUpdatePrice;
        uint256 tsGetQuote;
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);
        vm.assume(s.base != s.quote);

        s.baseDecimals = uint8(bound(s.baseDecimals, bounds.minBaseDecimals, bounds.maxBaseDecimals));
        s.quoteDecimals = uint8(bound(s.quoteDecimals, bounds.minQuoteDecimals, bounds.maxQuoteDecimals));
        s.feedDecimals = uint8(bound(s.feedDecimals, bounds.minFeedDecimals, bounds.maxFeedDecimals));

        s.maxPriceStaleness = uint32(bound(s.maxPriceStaleness, 0, 168 hours));
        s.maxCacheStaleness = uint32(bound(s.maxCacheStaleness, 0, 168 hours));

        vm.mockCall(s.base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.baseDecimals));
        vm.mockCall(s.quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(s.quoteDecimals));

        oracle = address(
            new RedstoneCoreOracleHarness(
                s.base, s.quote, s.feedId, s.feedDecimals, s.maxPriceStaleness, s.maxCacheStaleness
            )
        );

        vm.warp(s.maxCacheStaleness + 1);

        if (behaviors[Behavior.FeedReturnsZeroPrice]) {
            s.price = 0;
        } else {
            s.price = bound(s.price, bounds.minPrice, bounds.maxPrice);
        }

        s.tsDataPackage = bound(s.tsDataPackage, 2 ** 20, 2 ** 48);
        if (behaviors[Behavior.FeedReturnsStalePrice]) {
            s.tsUpdatePrice =
                bound(s.tsUpdatePrice, s.tsDataPackage + s.maxPriceStaleness + 1, 2 ** 48 + s.maxPriceStaleness + 1);
        } else {
            s.tsUpdatePrice = bound(s.tsUpdatePrice, s.tsDataPackage, s.tsDataPackage + s.maxPriceStaleness);
        }

        if (behaviors[Behavior.CachedPriceStale]) {
            s.tsGetQuote = bound(s.tsGetQuote, s.tsUpdatePrice + s.maxCacheStaleness + 1, type(uint64).max);
        } else {
            s.tsGetQuote = bound(s.tsGetQuote, s.tsUpdatePrice, s.tsUpdatePrice + s.maxCacheStaleness);
        }

        s.inAmount = bound(s.inAmount, bounds.minInAmount, bounds.maxInAmount);
    }

    function mockPrice(FuzzableState memory s) internal {
        vm.warp(s.tsUpdatePrice);
        RedstoneCoreOracleHarness(oracle).setPrice(s.price, s.tsDataPackage * 1000);
    }

    function setPrice(FuzzableState memory s) internal {
        RedstoneCoreOracleHarness(oracle).updatePrice();
        vm.warp(s.tsGetQuote);
    }

    function calcOutAmount(FuzzableState memory s) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDiv(
            s.inAmount, uint256(s.price) * 10 ** s.quoteDecimals, 10 ** (s.feedDecimals + s.baseDecimals)
        );
    }

    function calcOutAmountInverse(FuzzableState memory s) internal pure returns (uint256) {
        return FixedPointMathLib.fullMulDiv(
            s.inAmount, 10 ** (s.feedDecimals + s.baseDecimals), (uint256(s.price) * 10 ** s.quoteDecimals)
        );
    }
}
