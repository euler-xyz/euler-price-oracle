// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {AdapterPropTest} from "test/adapter/AdapterPropTest.sol";
import {CurveEMAOracleHelper} from "test/adapter/curve/CurveEMAOracleHelper.sol";
import {CurveEMAOracle} from "src/adapter/curve/CurveEMAOracle.sol";

contract CurveEMAOraclePropTest is CurveEMAOracleHelper, AdapterPropTest {
    function testProp_Bidirectional(FuzzableState memory s, Prop_Bidirectional memory p) public {
        setUpPropTest(s);
        checkProp(p);
    }

    function testProp_NoOtherPaths(FuzzableState memory s, Prop_NoOtherPaths memory p) public {
        setUpPropTest(s);
        checkProp(p);
    }

    function testProp_IdempotentQuoteAndQuotes(FuzzableState memory s, Prop_IdempotentQuoteAndQuotes memory p) public {
        setUpPropTest(s);
        checkProp(p);
    }

    function testProp_SupportsZero(FuzzableState memory s, Prop_SupportsZero memory p) public {
        setUpPropTest(s);
        checkProp(p);
    }

    function testProp_ContinuousDomain(FuzzableState memory s, Prop_ContinuousDomain memory p) public {
        setUpPropTest(s);
        checkProp(p);
    }

    function testProp_OutAmountIncreasing(FuzzableState memory s, Prop_OutAmountIncreasing memory p) public {
        setUpPropTest(s);
        checkProp(p);
    }

    function setUpPropTest(FuzzableState memory s) internal {
        setUpState(s);
        adapter = address(oracle);
        base = s.base;
        quote = s.coins_0;
    }
}
