// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {AdapterPropTest} from "test/adapter/AdapterPropTest.sol";
import {RethOracleHelper} from "test/adapter/rocketpool/RethOracleHelper.sol";

contract RethOraclePropTest is RethOracleHelper, AdapterPropTest {
    function testProp_Bidirectional(FuzzableState memory s, PropArgs_Bidirectional memory p) public {
        _setUpAdapter(s);
        _checkProp(p);
    }

    function testProp_NoOtherPaths(FuzzableState memory s, PropArgs_NoOtherPaths memory p) public {
        _setUpAdapter(s);
        _checkProp(p);
    }

    function testProp_ContinuousDomain(FuzzableState memory s, PropArgs_ContinuousDomain memory p) public {
        _setUpAdapter(s);
        _checkProp(p);
    }

    function testProp_OutAmountIncreasing(FuzzableState memory s, PropArgs_OutAmountIncreasing memory p) public {
        _setUpAdapter(s);
        _checkProp(p);
    }

    function _setUpAdapter(FuzzableState memory s) internal {
        _deployAndPrepare(s);
        adapter = address(oracle);
        base = RETH;
        quote = WETH;
    }
}
