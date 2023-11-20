// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import "forge-std/Test.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {IOracle} from "src/interfaces/IOracle.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {Aggregator} from "src/strategy/aggregator/Aggregator.sol";
import {MinAggregator} from "src/strategy/aggregator/MinAggregator.sol";

contract MinAggregatorTest is Test {
    function test_Constructor_RevertWhen_OraclesArrayIsTooLong(address[] memory _oracles, uint256 quorum) public {
        vm.assume(_oracles.length > 8);
        quorum = bound(quorum, 1, _oracles.length);
        vm.expectRevert(abi.encodeWithSelector(ImmutableAddressArray.ArrayTooLarge.selector, _oracles.length, 8));
        new MinAggregator(_oracles, quorum);
    }

    function test_Constructor_RevertWhen_OraclesArrayIsEmpty(uint256 quorum) public {
        vm.expectRevert(ImmutableAddressArray.ArrayEmpty.selector);
        new MinAggregator(new address[](0), 0);
    }

    function test_Constructor_RevertWhen_QuorumIsZero(address[] memory _oracles) public {
        vm.assume(_oracles.length <= 8 && _oracles.length > 0);
        vm.expectRevert(Aggregator.QuorumZero.selector);
        new MinAggregator(_oracles, 0);
    }

    function test_Constructor_RevertWhen_QuorumGtOraclesLength(address[] memory _oracles, uint256 quorum) public {
        vm.assume(_oracles.length <= 8 && _oracles.length > 0);
        quorum = bound(quorum, _oracles.length + 1, type(uint256).max);
        vm.expectRevert(abi.encodeWithSelector(Aggregator.QuorumTooLarge.selector, quorum, _oracles.length));
        new MinAggregator(_oracles, quorum);
    }
}
