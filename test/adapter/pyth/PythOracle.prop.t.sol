// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {PythStructs} from "@pyth/PythStructs.sol";
import {AdapterPropTest} from "test/adapter/AdapterPropTest.sol";
import {StubPyth} from "test/adapter/pyth/StubPyth.sol";
import {PythOracleHelper} from "test/adapter/pyth/PythOracleHelper.sol";

contract PythOraclePropTest is PythOracleHelper, AdapterPropTest {
    function testProp_Bidirectional(
        FuzzableConfig memory c,
        PythStructs.Price memory d,
        PropArgs_Bidirectional memory p
    ) public {
        _setUpAdapter(c, d);
        _checkProp(p);
    }

    function testProp_NoOtherPaths(FuzzableConfig memory c, PythStructs.Price memory d, PropArgs_NoOtherPaths memory p)
        public
    {
        _setUpAdapter(c, d);
        _checkProp(p);
    }

    function testProp_ContinuousDomain(
        FuzzableConfig memory c,
        PythStructs.Price memory d,
        PropArgs_ContinuousDomain memory p
    ) public {
        _setUpAdapter(c, d);
        _checkProp(p);
    }

    function testProp_OutAmountIncreasing(
        FuzzableConfig memory c,
        PythStructs.Price memory d,
        PropArgs_OutAmountIncreasing memory p
    ) public {
        _setUpAdapter(c, d);
        _checkProp(p);
    }

    function _setUpAdapter(FuzzableConfig memory c, PythStructs.Price memory d) internal {
        adapter = address(_deploy(c));
        _bound(d);
        StubPyth(PYTH).setPrice(d);
        base = c.base;
        quote = c.quote;
    }
}
