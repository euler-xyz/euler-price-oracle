// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {AggregatorHarness} from "test/utils/AggregatorHarness.sol";
import {boundAddr, boundAddrs, makeAddrs} from "test/utils/TestUtils.sol";
import {IOracle} from "src/interfaces/IOracle.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";

contract AggregatorTest is Test {
    function test_Constructor_RevertsWhen_OraclesArrayIsTooLong(address[] memory oracles, uint256 quorum) public {
        vm.assume(oracles.length > 8);
        quorum = bound(quorum, 1, oracles.length);
        vm.expectRevert(abi.encodeWithSelector(ImmutableAddressArray.ArrayTooLarge.selector, oracles.length, 8));
        new AggregatorHarness(oracles, quorum);
    }

    function test_Constructor_RevertsWhen_OraclesArrayIsEmpty(uint256 quorum) public {
        vm.expectRevert(ImmutableAddressArray.ArrayEmpty.selector);
        new AggregatorHarness(new address[](0), quorum);
    }

    function test_Constructor_RevertsWhen_QuorumIsZero(address[] memory oracles) public {
        vm.assume(oracles.length <= 8 && oracles.length > 0);
        vm.expectRevert(Aggregator.QuorumZero.selector);
        new AggregatorHarness(oracles, 0);
    }

    function test_Constructor_RevertsWhen_QuorumGtOraclesLength(address[] memory oracles, uint256 quorum) public {
        vm.assume(oracles.length <= 8 && oracles.length > 0);
        quorum = bound(quorum, oracles.length + 1, type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(Aggregator.QuorumTooLarge.selector, quorum, oracles.length));
        new AggregatorHarness(oracles, quorum);
    }

    function test_Constructor_Integrity(address[] memory oracles, uint256 quorum) public {
        vm.assume(oracles.length <= 8 && oracles.length > 0);
        quorum = bound(quorum, 1, oracles.length);
        AggregatorHarness aggregator = new AggregatorHarness(oracles, quorum);

        assertEq(aggregator.quorum(), quorum);
    }

    function test_GetQuote_RevertsWhen_NoAnswers(
        uint256 numOracles,
        uint256 quorum,
        uint256 inAmount,
        address base,
        address quote
    ) public {
        vm.assume(numOracles <= 8 && numOracles > 0);
        quorum = bound(quorum, 1, numOracles);
        address[] memory oracles = makeAddrs(numOracles);
        AggregatorHarness aggregator = new AggregatorHarness(oracles, quorum);

        for (uint256 i = 0; i < numOracles; ++i) {
            vm.mockCallRevert(oracles[i], abi.encodeWithSelector(IOracle.getQuote.selector), "oops");
        }

        vm.expectRevert(abi.encodeWithSelector(Aggregator.QuorumNotReached.selector, 0, quorum));
        aggregator.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_RevertsWhen_NoQuorum(
        uint256 numOracles,
        uint256 quorum,
        uint256 inAmount,
        address base,
        address quote
    ) public {
        vm.assume(numOracles <= 8 && numOracles > 0);
        quorum = bound(quorum, 1, numOracles);
        address[] memory oracles = makeAddrs(numOracles);
        AggregatorHarness aggregator = new AggregatorHarness(oracles, quorum);

        for (uint256 i = 0; i < quorum - 1; ++i) {
            vm.mockCall(oracles[i], abi.encodeWithSelector(IOracle.getQuote.selector), abi.encode(1));
        }

        for (uint256 i = quorum; i < numOracles; ++i) {
            vm.mockCallRevert(oracles[i], abi.encodeWithSelector(IOracle.getQuote.selector), "oops");
        }

        vm.expectRevert(abi.encodeWithSelector(Aggregator.QuorumNotReached.selector, quorum - 1, quorum));
        aggregator.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_Integrity(uint256 numOracles, uint256 quorum, uint256 inAmount, address base, address quote)
        public
    {
        vm.assume(numOracles <= 8 && numOracles > 0);
        quorum = bound(quorum, 1, numOracles);
        address[] memory oracles = makeAddrs(numOracles);
        AggregatorHarness aggregator = new AggregatorHarness(oracles, quorum);

        for (uint256 i = 0; i < quorum; ++i) {
            vm.mockCall(oracles[i], abi.encodeWithSelector(IOracle.getQuote.selector), abi.encode(1));
        }

        for (uint256 i = quorum + 1; i < numOracles; ++i) {
            vm.mockCallRevert(oracles[i], abi.encodeWithSelector(IOracle.getQuote.selector), "oops");
        }

        aggregator.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_Integrity_AggregateCallback(
        uint256 numOracles,
        uint256 quorum,
        uint256 inAmount,
        address base,
        address quote
    ) public {
        vm.assume(numOracles <= 8 && numOracles > 0);
        quorum = bound(quorum, 1, numOracles);
        address[] memory oracles = makeAddrs(numOracles);
        AggregatorHarness aggregator = new AggregatorHarness(oracles, quorum);

        for (uint256 i = 0; i < quorum; ++i) {
            vm.mockCall(oracles[i], abi.encodeWithSelector(IOracle.getQuote.selector), abi.encode(1));
        }

        for (uint256 i = quorum + 1; i < numOracles; ++i) {
            vm.mockCallRevert(oracles[i], abi.encodeWithSelector(IOracle.getQuote.selector), "oops");
        }

        aggregator.getQuote(inAmount, base, quote);
    }
}
