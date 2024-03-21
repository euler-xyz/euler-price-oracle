// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {AdapterPropTest} from "test/adapter/AdapterPropTest.sol";
import {RedstoneCoreOracleHelper} from "test/adapter/redstone/RedstoneCoreOracleHelper.sol";
import {RedstoneCoreOracleHarness} from "test/adapter/redstone/RedstoneCoreOracleHarness.sol";

contract RedstoneCoreOraclePropTest is RedstoneCoreOracleHelper, AdapterPropTest {
    function testProp_Bidirectional(FuzzableState memory s, PropArgs_Bidirectional memory p) public {
        setUpPropTest(s);
        checkProp(p);
    }

    function testProp_NoOtherPaths(FuzzableState memory s, PropArgs_NoOtherPaths memory p) public {
        setUpPropTest(s);
        checkProp(p);
    }

    function testProp_ContinuousDomain(FuzzableState memory s, PropArgs_ContinuousDomain memory p) public {
        setUpPropTest(s);
        checkProp(p);
    }

    function testProp_OutAmountIncreasing(FuzzableState memory s, PropArgs_OutAmountIncreasing memory p) public {
        setUpPropTest(s);
        checkProp(p);
    }

    function setUpPropTest(FuzzableState memory s) internal {
        setUpState(s);
        mockPrice(s);
        setPrice(s);
        adapter = address(oracle);
        base = s.base;
        quote = s.quote;
    }
}
