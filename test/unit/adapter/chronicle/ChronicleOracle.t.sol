// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IChronicle} from "@chronicle-std/IChronicle.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {ChronicleOracle} from "src/adapter/chronicle/ChronicleOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {IFactoryInitializable} from "src/interfaces/IFactoryInitializable.sol";
import {Errors} from "src/lib/Errors.sol";

contract ChronicleOracleTest is Test {
    address internal GOVERNOR = makeAddr("GOVERNOR");
    uint256 internal constant MAX_STALENESS = 1 days;

    ChronicleOracle oracle;

    function setUp() public {
        oracle = new ChronicleOracle(MAX_STALENESS);
        oracle.initialize(GOVERNOR);
    }

    function test_GovSetConfig_OnlyCallableByGovernor(address caller, FuzzableConfig memory c) public {
        vm.assume(caller != GOVERNOR);
        vm.prank(caller);
        vm.expectRevert(IFactoryInitializable.CallerNotGovernor.selector);
        oracle.govSetConfig(c.params);
    }

    function test_GovSetConfig_CallableByGovernor(FuzzableConfig memory c) public {
        _prepareValidConfig(c);
        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);
    }

    function test_GovSetConfig_Integrity(FuzzableConfig memory c) public {
        _prepareValidConfig(c);
        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        {
            (address feed, uint8 baseDecimals, uint8 quoteDecimals, bool inverse) =
                oracle.configs(c.params.base, c.params.quote);

            assertEq(feed, c.params.feed);
            assertEq(baseDecimals, c.baseDecimals);
            assertEq(quoteDecimals, c.quoteDecimals);
            assertEq(inverse, false);
        }

        {
            (address feed, uint8 baseDecimals, uint8 quoteDecimals, bool inverse) =
                oracle.configs(c.params.quote, c.params.base);

            assertEq(feed, c.params.feed);
            assertEq(baseDecimals, c.quoteDecimals);
            assertEq(quoteDecimals, c.baseDecimals);
            assertEq(inverse, true);
        }
    }

    function test_GovUnsetConfig_Integrity(FuzzableConfig memory c) public {
        _prepareValidConfig(c);

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.prank(GOVERNOR);
        oracle.govUnsetConfig(c.params.base, c.params.quote);

        {
            (address feed, uint8 baseDecimals, uint8 quoteDecimals, bool inverse) =
                oracle.configs(c.params.base, c.params.quote);

            assertEq(feed, address(0));
            assertEq(baseDecimals, 0);
            assertEq(quoteDecimals, 0);
            assertEq(inverse, false);
        }

        {
            (address feed, uint8 baseDecimals, uint8 quoteDecimals, bool inverse) =
                oracle.configs(c.params.quote, c.params.base);

            assertEq(feed, address(0));
            assertEq(baseDecimals, 0);
            assertEq(quoteDecimals, 0);
            assertEq(inverse, false);
        }
    }

    function test_GovUnsetConfig_Integrity_Reverse(FuzzableConfig memory c) public {
        _prepareValidConfig(c);

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.prank(GOVERNOR);
        oracle.govUnsetConfig(c.params.quote, c.params.base);

        {
            (address feed, uint8 baseDecimals, uint8 quoteDecimals, bool inverse) =
                oracle.configs(c.params.base, c.params.quote);

            assertEq(feed, address(0));
            assertEq(baseDecimals, 0);
            assertEq(quoteDecimals, 0);
            assertEq(inverse, false);
        }

        {
            (address feed, uint8 baseDecimals, uint8 quoteDecimals, bool inverse) =
                oracle.configs(c.params.quote, c.params.base);

            assertEq(feed, address(0));
            assertEq(baseDecimals, 0);
            assertEq(quoteDecimals, 0);
            assertEq(inverse, false);
        }
    }

    function test_GetQuote_RevertsWhen_NoConfig(FuzzableConfig memory c, uint256 inAmount) public {
        _prepareValidConfig(c);

        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, c.params.base, c.params.quote));
        oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    function test_GetQuote_RevertsWhen_ChronicleReverts(FuzzableConfig memory c, uint256 inAmount) public {
        _prepareValidConfig(c);
        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.mockCallRevert(c.params.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), "oops");
        vm.expectRevert();
        oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    function test_GetQuote_RevertsWhen_ZeroPrice(FuzzableConfig memory c, FuzzableAnswer memory a, uint256 inAmount)
        public
    {
        _prepareValidConfig(c);
        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        _prepareValidAnswer(a);
        a.price = 0;

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.mockCall(c.params.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(a));
        vm.expectRevert(abi.encodeWithSelector(Errors.Chronicle_InvalidPrice.selector, 0));
        oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    function test_GetQuote_RevertsWhen_TooStale(FuzzableConfig memory c, FuzzableAnswer memory a, uint256 inAmount)
        public
    {
        _prepareValidConfig(c);

        _prepareValidAnswer(a);
        a.age = bound(a.age, MAX_STALENESS + 1, uint256(type(uint128).max));

        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.mockCall(c.params.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(a));
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_TooStale.selector, a.age, MAX_STALENESS));
        oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    function test_GetQuote_Integrity(FuzzableConfig memory c, FuzzableAnswer memory a, uint256 inAmount) public {
        vm.skip(true);

        _prepareValidConfig(c);
        inAmount = bound(inAmount, 1, uint256(type(uint128).max));

        vm.prank(GOVERNOR);
        oracle.govSetConfig(c.params);

        vm.mockCall(c.params.feed, abi.encodeWithSelector(IChronicle.readWithAge.selector), abi.encode(a.price, a.age));
        uint256 res = oracle.getQuote(inAmount, c.params.base, c.params.quote);
    }

    struct FuzzableConfig {
        ChronicleOracle.ConfigParams params;
        uint8 baseDecimals;
        uint8 quoteDecimals;
    }

    function _prepareValidConfig(FuzzableConfig memory c) private {
        c.params.base = boundAddr(c.params.base);
        c.params.quote = boundAddr(c.params.quote);
        c.params.feed = boundAddr(c.params.feed);
        vm.assume(c.params.base != c.params.quote && c.params.quote != c.params.feed && c.params.base != c.params.feed);

        c.baseDecimals = uint8(bound(c.baseDecimals, 0, 24));
        c.quoteDecimals = uint8(bound(c.quoteDecimals, 0, 24));

        vm.mockCall(c.params.base, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.baseDecimals));
        vm.mockCall(c.params.quote, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(c.quoteDecimals));
    }

    struct FuzzableAnswer {
        uint256 price;
        uint256 age;
    }

    function _prepareValidAnswer(FuzzableAnswer memory a) private view {
        a.price = bound(a.price, 1, uint256(type(uint128).max));
    }
}
