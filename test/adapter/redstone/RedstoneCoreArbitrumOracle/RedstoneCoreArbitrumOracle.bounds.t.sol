// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {RedstoneCoreArbitrumOracleHelper} from
    "test/adapter/redstone/RedstoneCoreArbitrumOracle/RedstoneCoreArbitrumOracleHelper.sol";
import {RedstoneCoreArbitrumOracle} from "src/adapter/redstone/RedstoneCoreArbitrumOracle.sol";

contract RedstoneCoreArbitrumOracleBoundsTest is RedstoneCoreArbitrumOracleHelper {
    function test_Bounds_FeedWith8Decimals(FuzzableState memory s) public {
        setBounds(
            Bounds({
                minBaseDecimals: 0,
                maxBaseDecimals: 18,
                minQuoteDecimals: 0,
                maxQuoteDecimals: 18,
                minFeedDecimals: 8,
                maxFeedDecimals: 8,
                minInAmount: 0,
                maxInAmount: type(uint128).max,
                minPrice: 1,
                maxPrice: 1e15 * 1e8
            })
        );
        setUpState(s);
        mockPrice(s);
        setPrice(s);

        uint256 outAmount = RedstoneCoreArbitrumOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        assertEq(outAmount, calcOutAmount(s));

        uint256 outAmountInverse = RedstoneCoreArbitrumOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        assertEq(outAmountInverse, calcOutAmountInverse(s));
    }

    function test_Bounds_FeedWith18Decimals(FuzzableState memory s) public {
        setBounds(
            Bounds({
                minBaseDecimals: 0,
                maxBaseDecimals: 18,
                minQuoteDecimals: 0,
                maxQuoteDecimals: 18,
                minFeedDecimals: 8,
                maxFeedDecimals: 8,
                minInAmount: 0,
                maxInAmount: type(uint128).max,
                minPrice: 1,
                maxPrice: 1e15 * 1e8
            })
        );
        setUpState(s);
        mockPrice(s);
        setPrice(s);

        uint256 outAmount = RedstoneCoreArbitrumOracle(oracle).getQuote(s.inAmount, s.base, s.quote);
        assertEq(outAmount, calcOutAmount(s));

        uint256 outAmountInverse = RedstoneCoreArbitrumOracle(oracle).getQuote(s.inAmount, s.quote, s.base);
        assertEq(outAmountInverse, calcOutAmountInverse(s));
    }
}
