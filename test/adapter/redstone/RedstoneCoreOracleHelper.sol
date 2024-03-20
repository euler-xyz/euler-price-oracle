// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {RedstoneCoreOracleHarness} from "test/adapter/redstone/RedstoneCoreOracleHarness.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";

contract RedstoneCoreOracleHelper is Test {
    struct FuzzableConfig {
        address base;
        address quote;
        bytes32 feedId;
        uint32 maxStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
    }

    struct FuzzableAnswer {
        uint256 tsUpdatePrice;
        uint256 tsGetQuote;
        uint256 price;
    }

    function _deploy(FuzzableConfig memory c) internal returns (RedstoneCoreOracleHarness) {
        c.base = boundAddr(c.base);
        c.quote = boundAddr(c.quote);
        vm.assume(c.base != c.quote);

        c.baseDecimals = uint8(bound(c.baseDecimals, 2, 18));
        c.quoteDecimals = uint8(bound(c.quoteDecimals, 2, 18));
        c.maxStaleness = uint32(bound(c.maxStaleness, 3 minutes, 24 hours));

        vm.mockCall(c.base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(c.baseDecimals));
        vm.mockCall(c.quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(c.quoteDecimals));

        return new RedstoneCoreOracleHarness(c.base, c.quote, c.feedId, c.maxStaleness);
    }

    function _prepareValidAnswer(FuzzableAnswer memory d, uint256 maxStaleness) internal pure {
        d.tsUpdatePrice = bound(d.tsUpdatePrice, maxStaleness + 1, type(uint48).max - maxStaleness);
        d.tsGetQuote = bound(d.tsGetQuote, d.tsUpdatePrice, d.tsUpdatePrice + maxStaleness);
        d.price = bound(d.price, 1, type(uint128).max);
    }
}
