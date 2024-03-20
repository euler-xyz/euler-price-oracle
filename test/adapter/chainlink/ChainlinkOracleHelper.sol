// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {AggregatorV3Interface} from "src/adapter/chainlink/AggregatorV3Interface.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";

contract ChainlinkOracleHelper is Test {
    struct FuzzableConfig {
        address base;
        address quote;
        address feed;
        uint256 maxStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        uint8 feedDecimals;
    }

    struct FuzzableRoundData {
        uint80 roundId;
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    function _deploy(FuzzableConfig memory c) internal returns (ChainlinkOracle) {
        c.base = boundAddr(c.base);
        c.quote = boundAddr(c.quote);
        c.feed = boundAddr(c.feed);
        vm.assume(c.base != c.quote && c.quote != c.feed && c.base != c.feed);

        c.maxStaleness = bound(c.maxStaleness, 0, type(uint128).max);

        c.baseDecimals = uint8(bound(c.baseDecimals, 2, 18));
        c.quoteDecimals = uint8(bound(c.quoteDecimals, 2, 18));
        c.feedDecimals = uint8(bound(c.feedDecimals, 2, 18));

        vm.mockCall(c.base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(c.baseDecimals));
        vm.mockCall(c.quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(c.quoteDecimals));
        vm.mockCall(c.feed, abi.encodeWithSelector(AggregatorV3Interface.decimals.selector), abi.encode(c.feedDecimals));

        return new ChainlinkOracle(c.base, c.quote, c.feed, c.maxStaleness);
    }

    function _prepareValidRoundData(FuzzableRoundData memory d) internal pure {
        d.answer = bound(d.answer, 1, (type(int64).max));
        d.updatedAt = bound(d.updatedAt, 1, type(uint128).max);
    }
}
