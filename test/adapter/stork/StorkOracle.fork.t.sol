// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;


import {ForkTest} from "test/utils/ForkTest.sol";
import {StorkOracle} from "../../../src/adapter/stork/StorkOracle.sol";
import {StorkStructs, IStorkTemporalNumericValueUnsafeGetter} from "../../../src/adapter/stork/IStork.sol";
import {BTC, USD} from "test/utils/EthereumAddresses.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";


contract StorkOracleForkTest is ForkTest {
    using stdStorage for StdStorage;

    StorkOracle oracle;

    address storkContractAddress = 0x035B5438444f26e6Aab81E91d475b7B1Ac4Fb22b;
    bytes32 feedId = 0x7404e3d104ea7841c3d9e6fd20adfe99b4ad586bc08d8f3bd3afef894cf184de; // BTCUSD
    address base = BTC;
    address quote = USD;
    uint256 blockNumber = 22241301;
    uint256 expectedValue = 79749.8e18;

    function setUp() public {
        _setUpFork(blockNumber);
    }

    function test_GetQuote_Integrity() public {
        oracle = new StorkOracle(storkContractAddress, base, quote, feedId, 15 minutes);

        uint256 outAmount = oracle.getQuote(1e18, base, quote);
        assertApproxEqRel(outAmount, expectedValue, 0.1e18);
        uint256 outAmountInverse = oracle.getQuote(expectedValue, quote, base);
        assertApproxEqRel(outAmountInverse, 1e18, 0.1e18);
    }

    function test_GetQuotes_Integrity() public {
        oracle = new StorkOracle(storkContractAddress, base, quote, feedId, 15 minutes);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(1e18, base, quote);
        assertApproxEqRel(bidOutAmount, expectedValue, 0.1e18);
        assertApproxEqRel(askOutAmount, expectedValue, 0.1e18);
        assertEq(bidOutAmount, askOutAmount);

        (uint256 bidOutAmountInverse, uint256 askOutAmountInverse) = oracle.getQuotes(expectedValue, quote, base);
        assertApproxEqRel(bidOutAmountInverse, 1e18, 0.1e18);
        assertApproxEqRel(askOutAmountInverse, 1e18, 0.1e18);
        assertEq(bidOutAmountInverse, askOutAmountInverse);
    }
}
