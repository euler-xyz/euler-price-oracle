// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import "forge-std/Test.sol";
import {AggregatorHarness} from "test/utils/AggregatorHarness.sol";
import {boundAddr, boundAddrs, makeAddrs} from "test/utils/TestUtils.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";

contract AggregatorTest is Test {
    function test_Initialize_RevertsWhen_OraclesArrayIsEmpty(uint256 quorum) public {
        AggregatorHarness aggregator = new AggregatorHarness();
        vm.expectRevert(Errors.Aggregator_OraclesEmpty.selector);
        aggregator.initialize(address(this), abi.encode(new address[](0), quorum));
    }

    function test_Initialize_RevertsWhen_QuorumIsZero(address[] memory oracles) public {
        vm.assume(oracles.length <= 8 && oracles.length > 0);
        AggregatorHarness aggregator = new AggregatorHarness();
        vm.expectRevert(Errors.Aggregator_QuorumZero.selector);
        aggregator.initialize(address(this), abi.encode(oracles, 0));
    }

    function test_Initialize_RevertsWhen_QuorumGtOraclesLength(address[] memory oracles, uint256 quorum) public {
        vm.assume(oracles.length <= 8 && oracles.length > 0);
        quorum = bound(quorum, oracles.length + 1, type(uint256).max);
        AggregatorHarness aggregator = new AggregatorHarness();
        vm.expectRevert(abi.encodeWithSelector(Errors.Aggregator_QuorumTooLarge.selector, quorum, oracles.length));
        aggregator.initialize(address(this), abi.encode(oracles, quorum));
    }

    function test_Initialize_Integrity(address[] memory oracles, uint256 quorum) public {
        vm.assume(oracles.length <= 8 && oracles.length > 0);
        quorum = bound(quorum, 1, oracles.length);
        AggregatorHarness aggregator = new AggregatorHarness();
        aggregator.initialize(address(this), abi.encode(oracles, quorum));
        assertEq(aggregator.quorum(), quorum);
    }

    function test_GetQuote_RevertsWhen_EOracle_NoAnswers(
        uint256 numOracles,
        uint256 quorum,
        uint256 inAmount,
        address base,
        address quote
    ) public {
        vm.assume(numOracles <= 8 && numOracles > 0);
        quorum = bound(quorum, 1, numOracles);
        address[] memory oracles = makeAddrs(numOracles);
        AggregatorHarness aggregator = new AggregatorHarness();
        aggregator.initialize(address(this), abi.encode(oracles, quorum));

        for (uint256 i = 0; i < numOracles; ++i) {
            vm.mockCallRevert(oracles[i], abi.encodeWithSelector(IEOracle.getQuote.selector), "oops");
        }

        vm.expectRevert(abi.encodeWithSelector(Errors.Aggregator_QuorumNotReached.selector, 0, quorum));
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
        AggregatorHarness aggregator = new AggregatorHarness();
        aggregator.initialize(address(this), abi.encode(oracles, quorum));

        for (uint256 i = 0; i < quorum - 1; ++i) {
            vm.mockCall(oracles[i], abi.encodeWithSelector(IEOracle.getQuote.selector), abi.encode(1));
        }

        for (uint256 i = quorum; i < numOracles; ++i) {
            vm.mockCallRevert(oracles[i], abi.encodeWithSelector(IEOracle.getQuote.selector), "oops");
        }

        vm.expectRevert(abi.encodeWithSelector(Errors.Aggregator_QuorumNotReached.selector, quorum - 1, quorum));
        aggregator.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_Integrity(uint256 numOracles, uint256 quorum, uint256 inAmount, address base, address quote)
        public
    {
        vm.assume(numOracles <= 8 && numOracles > 0);
        quorum = bound(quorum, 1, numOracles);
        address[] memory oracles = makeAddrs(numOracles);
        AggregatorHarness aggregator = new AggregatorHarness();
        aggregator.initialize(address(this), abi.encode(oracles, quorum));

        for (uint256 i = 0; i < quorum; ++i) {
            vm.mockCall(oracles[i], abi.encodeWithSelector(IEOracle.getQuote.selector), abi.encode(1));
        }

        for (uint256 i = quorum + 1; i < numOracles; ++i) {
            vm.mockCallRevert(oracles[i], abi.encodeWithSelector(IEOracle.getQuote.selector), "oops");
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
        AggregatorHarness aggregator = new AggregatorHarness();
        aggregator.initialize(address(this), abi.encode(oracles, quorum));

        for (uint256 i = 0; i < quorum; ++i) {
            vm.mockCall(oracles[i], abi.encodeWithSelector(IEOracle.getQuote.selector), abi.encode(1));
        }

        for (uint256 i = quorum + 1; i < numOracles; ++i) {
            vm.mockCallRevert(oracles[i], abi.encodeWithSelector(IEOracle.getQuote.selector), "oops");
        }

        aggregator.getQuote(inAmount, base, quote);
    }
}
