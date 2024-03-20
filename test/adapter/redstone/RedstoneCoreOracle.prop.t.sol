// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {AdapterPropTest} from "test/adapter/AdapterPropTest.sol";
import {RedstoneCoreOracleHelper} from "test/adapter/redstone/RedstoneCoreOracleHelper.sol";
import {RedstoneCoreOracleHarness} from "test/adapter/redstone/RedstoneCoreOracleHarness.sol";

contract RedstoneCoreOraclePropTest is RedstoneCoreOracleHelper, AdapterPropTest {
    function testProp_Bidirectional(FuzzableConfig memory c, FuzzableAnswer memory d, PropArgs_Bidirectional memory p)
        public
    {
        _setUpAdapter(c, d);
        _checkProp(p);
    }

    function testProp_NoOtherPaths(FuzzableConfig memory c, FuzzableAnswer memory d, PropArgs_NoOtherPaths memory p)
        public
    {
        _setUpAdapter(c, d);
        _checkProp(p);
    }

    function testProp_ContinuousDomain(
        FuzzableConfig memory c,
        FuzzableAnswer memory d,
        PropArgs_ContinuousDomain memory p
    ) public {
        _setUpAdapter(c, d);
        _checkProp(p);
    }

    function testProp_OutAmountIncreasing(
        FuzzableConfig memory c,
        FuzzableAnswer memory d,
        PropArgs_OutAmountIncreasing memory p
    ) public {
        _setUpAdapter(c, d);
        _checkProp(p);
    }

    function _setUpAdapter(FuzzableConfig memory c, FuzzableAnswer memory d) internal {
        adapter = address(_deploy(c));
        base = c.base;
        quote = c.quote;

        _prepareValidAnswer(d, c.maxStaleness);
        vm.warp(d.tsUpdatePrice);
        RedstoneCoreOracleHarness(adapter).setPrice(d.price);
        RedstoneCoreOracleHarness(adapter).updatePrice();
        vm.warp(d.tsGetQuote);
    }
}
