// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {Errors} from "src/lib/Errors.sol";
import {BackupAggregator} from "src/aggregator/BackupAggregator.sol";

contract BackupAggregatorTest is Test {
    // BackupAggregator aggregator;

    // function setUp() public {
    //     aggregator = new BackupAggregator();
    // }

    function test_Constructor_Integrity(address firstOracle, address secondOracle, address thirdOracle) public {
        BackupAggregator aggregator = new BackupAggregator(firstOracle, secondOracle, thirdOracle);
        assertEq(aggregator.firstOracle(), firstOracle);
        assertEq(aggregator.secondOracle(), secondOracle);
        assertEq(aggregator.thirdOracle(), thirdOracle);
    }

    function test_Quote_OneOracle_FirstReturns(uint256 inAmount, address base, address quote, uint256 returnValue)
        public
    {
        address firstOracle = address(new StubPriceOracle(false, returnValue));
        BackupAggregator aggregator = new BackupAggregator(firstOracle, address(0), address(0));

        uint256 outAmount = aggregator.getQuote(inAmount, base, quote);
        assertEq(outAmount, returnValue);

        (uint256 bidOutAmount, uint256 askOutAmount) = aggregator.getQuotes(inAmount, base, quote);
        assertEq(bidOutAmount, returnValue);
        assertEq(askOutAmount, returnValue);
    }

    function test_Quote_OneOracle_FirstReverts(uint256 inAmount, address base, address quote, uint256 returnValue)
        public
    {
        address firstOracle = address(new StubPriceOracle(true, returnValue));
        BackupAggregator aggregator = new BackupAggregator(firstOracle, address(0), address(0));

        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        aggregator.getQuote(inAmount, base, quote);

        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        aggregator.getQuotes(inAmount, base, quote);
    }

    function test_Quote_TwoOracles_FirstReturns(
        uint256 inAmount,
        address base,
        address quote,
        uint256 returnValue1,
        uint256 returnValue2
    ) public {
        address firstOracle = address(new StubPriceOracle(false, returnValue1));
        address secondOracle = address(new StubPriceOracle(false, returnValue2));
        BackupAggregator aggregator = new BackupAggregator(firstOracle, secondOracle, address(0));

        uint256 outAmount = aggregator.getQuote(inAmount, base, quote);
        assertEq(outAmount, returnValue1);

        (uint256 bidOutAmount, uint256 askOutAmount) = aggregator.getQuotes(inAmount, base, quote);
        assertEq(bidOutAmount, returnValue1);
        assertEq(askOutAmount, returnValue1);
    }

    function test_Quote_TwoOracles_FirstReverts_SecondReturns(
        uint256 inAmount,
        address base,
        address quote,
        uint256 returnValue1,
        uint256 returnValue2
    ) public {
        address firstOracle = address(new StubPriceOracle(true, returnValue1));
        address secondOracle = address(new StubPriceOracle(false, returnValue2));
        BackupAggregator aggregator = new BackupAggregator(firstOracle, secondOracle, address(0));

        uint256 outAmount = aggregator.getQuote(inAmount, base, quote);
        assertEq(outAmount, returnValue2);

        (uint256 bidOutAmount, uint256 askOutAmount) = aggregator.getQuotes(inAmount, base, quote);
        assertEq(bidOutAmount, returnValue2);
        assertEq(askOutAmount, returnValue2);
    }

    function test_Quote_TwoOracles_FirstReverts_SecondReverts(
        uint256 inAmount,
        address base,
        address quote,
        uint256 returnValue1,
        uint256 returnValue2
    ) public {
        address firstOracle = address(new StubPriceOracle(true, returnValue1));
        address secondOracle = address(new StubPriceOracle(true, returnValue2));
        BackupAggregator aggregator = new BackupAggregator(firstOracle, secondOracle, address(0));

        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        aggregator.getQuote(inAmount, base, quote);

        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        aggregator.getQuotes(inAmount, base, quote);
    }

    function test_Quote_ThreeOracles_FirstReturns(
        uint256 inAmount,
        address base,
        address quote,
        uint256 returnValue1,
        uint256 returnValue2,
        uint256 returnValue3
    ) public {
        address firstOracle = address(new StubPriceOracle(false, returnValue1));
        address secondOracle = address(new StubPriceOracle(false, returnValue2));
        address thirdOracle = address(new StubPriceOracle(false, returnValue3));
        BackupAggregator aggregator = new BackupAggregator(firstOracle, secondOracle, thirdOracle);

        uint256 outAmount = aggregator.getQuote(inAmount, base, quote);
        assertEq(outAmount, returnValue1);

        (uint256 bidOutAmount, uint256 askOutAmount) = aggregator.getQuotes(inAmount, base, quote);
        assertEq(bidOutAmount, returnValue1);
        assertEq(askOutAmount, returnValue1);
    }

    function test_Quote_TwoOracles_FirstReverts_SecondReturns(
        uint256 inAmount,
        address base,
        address quote,
        uint256 returnValue1,
        uint256 returnValue2,
        uint256 returnValue3
    ) public {
        address firstOracle = address(new StubPriceOracle(true, returnValue1));
        address secondOracle = address(new StubPriceOracle(false, returnValue2));
        address thirdOracle = address(new StubPriceOracle(false, returnValue3));
        BackupAggregator aggregator = new BackupAggregator(firstOracle, secondOracle, thirdOracle);

        uint256 outAmount = aggregator.getQuote(inAmount, base, quote);
        assertEq(outAmount, returnValue2);

        (uint256 bidOutAmount, uint256 askOutAmount) = aggregator.getQuotes(inAmount, base, quote);
        assertEq(bidOutAmount, returnValue2);
        assertEq(askOutAmount, returnValue2);
    }

    function test_Quote_TwoOracles_FirstReverts_SecondReverts_ThirdReturns(
        uint256 inAmount,
        address base,
        address quote,
        uint256 returnValue1,
        uint256 returnValue2,
        uint256 returnValue3
    ) public {
        address firstOracle = address(new StubPriceOracle(true, returnValue1));
        address secondOracle = address(new StubPriceOracle(true, returnValue2));
        address thirdOracle = address(new StubPriceOracle(false, returnValue3));
        BackupAggregator aggregator = new BackupAggregator(firstOracle, secondOracle, thirdOracle);

        uint256 outAmount = aggregator.getQuote(inAmount, base, quote);
        assertEq(outAmount, returnValue3);

        (uint256 bidOutAmount, uint256 askOutAmount) = aggregator.getQuotes(inAmount, base, quote);
        assertEq(bidOutAmount, returnValue3);
        assertEq(askOutAmount, returnValue3);
    }

    function test_Quote_TwoOracles_FirstReverts_SecondReverts_ThirdReverts(
        uint256 inAmount,
        address base,
        address quote,
        uint256 returnValue1,
        uint256 returnValue2,
        uint256 returnValue3
    ) public {
        address firstOracle = address(new StubPriceOracle(true, returnValue1));
        address secondOracle = address(new StubPriceOracle(true, returnValue2));
        address thirdOracle = address(new StubPriceOracle(true, returnValue3));
        BackupAggregator aggregator = new BackupAggregator(firstOracle, secondOracle, thirdOracle);

        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        aggregator.getQuote(inAmount, base, quote);

        vm.expectRevert(Errors.PriceOracle_InvalidAnswer.selector);
        aggregator.getQuotes(inAmount, base, quote);
    }
}

contract StubPriceOracle {
    bool immutable doRevert;
    uint256 immutable returnValue;

    constructor(bool _doRevert, uint256 _returnValue) {
        doRevert = _doRevert;
        returnValue = _returnValue;
    }

    function getQuote(uint256, address, address) external view returns (uint256) {
        if (doRevert) revert("");
        return returnValue;
    }

    function getQuotes(uint256, address, address) external view returns (uint256, uint256) {
        if (doRevert) revert("");
        return (returnValue, returnValue);
    }
}
