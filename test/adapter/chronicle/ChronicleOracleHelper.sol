// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {IChronicle} from "src/adapter/chronicle/IChronicle.sol";
import {ChronicleOracle} from "src/adapter/chronicle/ChronicleOracle.sol";

contract ChronicleOracleHelper is Test {
    struct FuzzableConfig {
        address base;
        address quote;
        address feed;
        uint256 maxStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
        uint8 feedDecimals;
    }

    struct FuzzableAnswer {
        uint256 value;
        uint256 age;
    }

    function _deploy(FuzzableConfig memory c) internal returns (ChronicleOracle) {
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
        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.decimals.selector), abi.encode(c.feedDecimals));

        return new ChronicleOracle(c.base, c.quote, c.feed, c.maxStaleness);
    }

    function _prepareValidAnswer(FuzzableAnswer memory d, uint256 maxStaleness) internal pure {
        d.value = bound(d.value, 1, (type(uint64).max));
        d.age = bound(d.age, 0, maxStaleness);
    }
}
