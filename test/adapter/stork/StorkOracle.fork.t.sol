// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;


import {ForkTest} from "test/utils/ForkTest.sol";
import {StorkOracle} from "../../../src/adapter/stork/StorkOracle.sol";
import {StorkStructs, IStorkTemporalNumericValueUnsafeGetter} from "../../../src/adapter/stork/IStork.sol";
import {USD} from "test/utils/EthereumAddresses.sol";
import {stdStorage, StdStorage} from "forge-std/StdStorage.sol";


contract StorkOracleForkTest is ForkTest {
    using stdStorage for StdStorage;

    StorkOracle oracle;

    address storkContractAddress = 0xacC0a0cF13571d30B4b8637996F5D6D774d4fd62;
    bytes32 feedId = 0x9c7a8f90aa21b1e368d1a5f7b4d75aa03fec9abb903d84946ef76fd6fd79b312; // BERAUSD
    address base = 0x6969696969696969696969696969696969696969; // BERA
    address quote = USD;
    uint256 blockNumber = 3527772;
    uint256 expectedValue = 3.82e18;

    function setUp() public {
        _setUpFork(blockNumber);
    }

    function test_GetQuote_Integrity() public {
        oracle = new StorkOracle(storkContractAddress, base, quote, feedId, 15 minutes);
        StorkStructs.TemporalNumericValue memory v = IStorkTemporalNumericValueUnsafeGetter(storkContractAddress).getTemporalNumericValueUnsafeV1(feedId);

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
