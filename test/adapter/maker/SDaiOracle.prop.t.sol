// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {AdapterPropTest} from "test/adapter/AdapterPropTest.sol";
import {SDaiOracleHelper} from "test/adapter/maker/SDaiOracleHelper.sol";

contract SDaiOraclePropTest is SDaiOracleHelper, AdapterPropTest {
    function testProp_Bidirectional(FuzzableAnswer memory c, PropArgs_Bidirectional memory p) public {
        _setUpAdapter(c);
        _checkProp(p);
    }

    function testProp_NoOtherPaths(FuzzableAnswer memory c, PropArgs_NoOtherPaths memory p) public {
        _setUpAdapter(c);
        _checkProp(p);
    }

    function testProp_ContinuousDomain(FuzzableAnswer memory c, PropArgs_ContinuousDomain memory p) public {
        _setUpAdapter(c);
        _checkProp(p);
    }

    function testProp_OutAmountIncreasing(FuzzableAnswer memory c, PropArgs_OutAmountIncreasing memory p) public {
        _setUpAdapter(c);
        _checkProp(p);
    }

    function _setUpAdapter(FuzzableAnswer memory c) internal {
        adapter = address(_deploy());
        _prepareAnswer(c);
        base = DAI;
        quote = SDAI;
    }
}
