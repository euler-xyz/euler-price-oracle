// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {arrOf} from "test/utils/TestUtils.sol";
import {FeedRegistry} from "src/FeedRegistry.sol";
import {Errors} from "src/lib/Errors.sol";
import {FeedIdentifier, FeedIdentifierLib} from "src/lib/FeedIdentifier.sol";

contract FeedRegistryTest is Test {
    address GOVERNOR = makeAddr("GOVERNOR");
    FeedRegistry registry;

    function setUp() public {
        registry = new FeedRegistry(GOVERNOR);
    }

    function test_GovSetFeeds_RevertsWhen_NotGovernor(
        address caller,
        address[] memory bases,
        address[] memory quotes,
        FeedIdentifier[] memory feeds
    ) public {
        vm.assume(caller != GOVERNOR);
        vm.prank(caller);
        vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
        registry.govSetFeeds(bases, quotes, feeds);
    }

    function test_GovSetFeeds_RevertsWhen_ArityMismatch(uint256 arityBases, uint256 arityQuotes, uint256 arityFeeds)
        public
    {
        arityBases = bound(arityBases, 1, 10);
        arityQuotes = bound(arityQuotes, 1, 10);
        arityFeeds = bound(arityFeeds, 1, 10);
        vm.assume(arityBases != arityQuotes || arityQuotes != arityFeeds || arityFeeds != arityBases);

        vm.prank(GOVERNOR);
        vm.expectRevert(Errors.FeedRegistry_InvalidConfiguration.selector);
        registry.govSetFeeds(new address[](arityBases), new address[](arityQuotes), new FeedIdentifier[](arityFeeds));
    }

    function test_GovSetFeeds_RevertsWhen_Duplicate_1() public {
        address[] memory bases = arrOf(makeAddr("base0"), makeAddr("base1"), makeAddr("base1"));
        address[] memory quotes = arrOf(makeAddr("quote0"), makeAddr("quote1"), makeAddr("quote1"));
        FeedIdentifier[] memory feeds = arrOf(
            FeedIdentifierLib.fromBytes32(keccak256("feed0")),
            FeedIdentifierLib.fromBytes32(keccak256("feed1")),
            FeedIdentifierLib.fromBytes32(keccak256("feed2"))
        );

        vm.prank(GOVERNOR);
        vm.expectRevert(Errors.FeedRegistry_InvalidConfiguration.selector);
        registry.govSetFeeds(bases, quotes, feeds);
    }

    function test_GovSetFeeds_RevertsWhen_Duplicate_2() public {
        address[] memory bases = arrOf(makeAddr("base0"), makeAddr("base0"), makeAddr("base1"));
        address[] memory quotes = arrOf(makeAddr("quote0"), makeAddr("quote0"), makeAddr("quote1"));
        FeedIdentifier[] memory feeds = arrOf(
            FeedIdentifierLib.fromBytes32(keccak256("feed0")),
            FeedIdentifierLib.fromBytes32(keccak256("feed1")),
            FeedIdentifierLib.fromBytes32(keccak256("feed2"))
        );

        vm.prank(GOVERNOR);
        vm.expectRevert(Errors.FeedRegistry_InvalidConfiguration.selector);
        registry.govSetFeeds(bases, quotes, feeds);
    }

    function test_GovSetFeeds_RevertsWhen_Duplicate_3() public {
        address[] memory bases = arrOf(makeAddr("base0"), makeAddr("base1"), makeAddr("base0"));
        address[] memory quotes = arrOf(makeAddr("quote0"), makeAddr("quote1"), makeAddr("quote0"));
        FeedIdentifier[] memory feeds = arrOf(
            FeedIdentifierLib.fromBytes32(keccak256("feed0")),
            FeedIdentifierLib.fromBytes32(keccak256("feed1")),
            FeedIdentifierLib.fromBytes32(keccak256("feed2"))
        );

        vm.prank(GOVERNOR);
        vm.expectRevert(Errors.FeedRegistry_InvalidConfiguration.selector);
        registry.govSetFeeds(bases, quotes, feeds);
    }

    function test_GovSetFeeds_Integrity() public {
        address[] memory bases = arrOf(makeAddr("base0"), makeAddr("base1"), makeAddr("base2"));
        address[] memory quotes = arrOf(makeAddr("quote0"), makeAddr("quote1"), makeAddr("quote2"));
        FeedIdentifier[] memory feeds = arrOf(
            FeedIdentifierLib.fromBytes32(keccak256("feed0")),
            FeedIdentifierLib.fromBytes32(keccak256("feed1")),
            FeedIdentifierLib.fromBytes32(keccak256("feed2"))
        );

        vm.prank(GOVERNOR);
        registry.govSetFeeds(bases, quotes, feeds);
        assertEq(registry.getFeed(makeAddr("base0"), makeAddr("quote0")).toBytes32(), keccak256("feed0"));
        assertEq(registry.getFeed(makeAddr("base1"), makeAddr("quote1")).toBytes32(), keccak256("feed1"));
        assertEq(registry.getFeed(makeAddr("base2"), makeAddr("quote2")).toBytes32(), keccak256("feed2"));
    }
}
