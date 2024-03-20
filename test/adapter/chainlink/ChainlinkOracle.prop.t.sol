// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {AdapterPropTest} from "test/adapter/AdapterPropTest.sol";
import {ChainlinkOracleHelper} from "test/adapter/chainlink/ChainlinkOracleHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {AggregatorV3Interface} from "src/adapter/chainlink/AggregatorV3Interface.sol";
import {ChainlinkOracle} from "src/adapter/chainlink/ChainlinkOracle.sol";

contract ChainlinkOraclePropTest is ChainlinkOracleHelper, AdapterPropTest {
    function testProp_Bidirectional(
        FuzzableConfig memory c,
        FuzzableRoundData memory d,
        uint256 timestamp,
        PropArgs_Bidirectional memory p
    ) public {
        _setUpAdapter(c, d, timestamp);
        _checkProp(p);
    }

    function testProp_NoOtherPaths(
        FuzzableConfig memory c,
        FuzzableRoundData memory d,
        uint256 timestamp,
        PropArgs_NoOtherPaths memory p
    ) public {
        _setUpAdapter(c, d, timestamp);
        _checkProp(p);
    }

    function testProp_ContinuousDomain(
        FuzzableConfig memory c,
        FuzzableRoundData memory d,
        uint256 timestamp,
        PropArgs_ContinuousDomain memory p
    ) public {
        _setUpAdapter(c, d, timestamp);
        _checkProp(p);
    }

    function testProp_OutAmountIncreasing(
        FuzzableConfig memory c,
        FuzzableRoundData memory d,
        uint256 timestamp,
        PropArgs_OutAmountIncreasing memory p
    ) public {
        _setUpAdapter(c, d, timestamp);
        _checkProp(p);
    }

    function _setUpAdapter(FuzzableConfig memory c, FuzzableRoundData memory d, uint256 timestamp) internal {
        adapter = address(_deploy(c));
        base = c.base;
        quote = c.quote;

        _prepareValidRoundData(d);
        vm.mockCall(c.feed, abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector), abi.encode(d));
        timestamp = bound(timestamp, d.updatedAt, d.updatedAt + c.maxStaleness);
        vm.warp(timestamp);
    }
}
