// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {AdapterPropTest} from "test/adapter/AdapterPropTest.sol";
import {ChronicleOracleHelper} from "test/adapter/chronicle/ChronicleOracleHelper.sol";
import {IChronicle} from "src/adapter/chronicle/IChronicle.sol";
import {ChronicleOracle} from "src/adapter/chronicle/ChronicleOracle.sol";

contract ChronicleOraclePropTest is ChronicleOracleHelper, AdapterPropTest {
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
        _prepareValidAnswer(d, c.maxStaleness);
        vm.mockCall(c.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(d));
        base = c.base;
        quote = c.quote;
    }
}
