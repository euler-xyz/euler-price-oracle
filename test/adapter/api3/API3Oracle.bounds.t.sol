// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {API3OracleHelper} from "test/adapter/api3/API3OracleHelper.sol";
import {API3Oracle} from "src/adapter/api3/API3Oracle.sol";

contract API3OracleBoundsTest is API3OracleHelper {
    function test_Bounds(FuzzableState memory s) public {
        setBounds(
            Bounds({
                minBaseDecimals: 0,
                maxBaseDecimals: 18,
                minQuoteDecimals: 0,
                maxQuoteDecimals: 18,
                minInAmount: 0,
                maxInAmount: type(uint128).max,
                minAnswer: 1,
                maxAnswer: 1e8 * 1e18
            })
        );
        setUpState(s);

        uint256 outAmount = API3Oracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        assertEq(outAmount, calcOutAmount(s));

        uint256 outAmountInverse = API3Oracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        assertEq(outAmountInverse, calcOutAmountInverse(s));
    }
}
