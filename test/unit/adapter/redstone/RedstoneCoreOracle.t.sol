// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {RedstoneCoreOracleHarness} from "test/utils/RedstoneCoreOracleHarness.sol";
import {RedstoneCoreOracle} from "src/adapter/redstone/RedstoneCoreOracle.sol";
import {IFactoryInitializable} from "src/interfaces/IFactoryInitializable.sol";
import {Errors} from "src/lib/Errors.sol";

contract RedstoneCoreOracleTest is Test {
    address internal GOVERNOR = makeAddr("GOVERNOR");
    address internal WETH = makeAddr("WETH");
    address internal RETH = makeAddr("RETH");

    RedstoneCoreOracleHarness oracle;

    function setUp() public {
        oracle = new RedstoneCoreOracleHarness();
        oracle.initialize(GOVERNOR);
    }

    function test_GovSetConfig_Integrity(
        RedstoneCoreOracle.ConfigParams memory params,
        uint8 _baseDecimals,
        uint8 _quoteDecimals
    ) public {
        params.base = boundAddr(params.base);
        params.quote = boundAddr(params.quote);
        vm.assume(params.base != params.quote);
        vm.mockCall(params.base, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(_baseDecimals));
        vm.mockCall(params.quote, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(_quoteDecimals));
        vm.prank(GOVERNOR);
        oracle.govSetConfig(params);

        (bytes32 feedId, uint32 maxStaleness, uint8 baseDecimals, uint8 quoteDecimals, bool inverse) =
            oracle.configs(params.base, params.quote);
        assertEq(feedId, params.feedId);
        assertEq(maxStaleness, params.maxStaleness);
        assertEq(baseDecimals, _baseDecimals);
        assertEq(quoteDecimals, _quoteDecimals);
        assertEq(inverse, params.inverse);

        (feedId, maxStaleness, baseDecimals, quoteDecimals, inverse) = oracle.configs(params.quote, params.base);
        assertEq(feedId, params.feedId);
        assertEq(maxStaleness, params.maxStaleness);
        assertEq(baseDecimals, _quoteDecimals);
        assertEq(quoteDecimals, _baseDecimals);
        assertEq(inverse, !params.inverse);
    }

    function test_GovSetConfig_RevertsWhen_CallerNotGovernor(
        RedstoneCoreOracle.ConfigParams memory params,
        uint8 _baseDecimals,
        uint8 _quoteDecimals,
        address caller
    ) public {
        vm.assume(caller != GOVERNOR);
        params.base = boundAddr(params.base);
        params.quote = boundAddr(params.quote);
        vm.assume(params.base != params.quote);
        vm.mockCall(params.base, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(_baseDecimals));
        vm.mockCall(params.quote, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(_quoteDecimals));

        vm.prank(caller);
        vm.expectRevert(IFactoryInitializable.CallerNotGovernor.selector);
        oracle.govSetConfig(params);
    }

    function test_GetQuote_RevertsWhen_NoConfig(uint256 inAmount, address base, address quote) public {
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuote(inAmount, base, quote);
    }

    function test_GetQuote_Integrity(
        RedstoneCoreOracle.ConfigParams memory params,
        uint8 _baseDecimals,
        uint8 _quoteDecimals,
        uint256 inAmount,
        uint256 price
    ) public {
        inAmount = bound(inAmount, 1, type(uint128).max);
        price = bound(price, 1, type(uint128).max);
        _baseDecimals = uint8(bound(_baseDecimals, 0, 27));
        _quoteDecimals = uint8(bound(_quoteDecimals, 0, 27));
        params.base = boundAddr(params.base);
        params.quote = boundAddr(params.quote);
        vm.assume(params.base != params.quote);
        vm.assume(params.feedId != 0);
        vm.mockCall(params.base, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(_baseDecimals));
        vm.mockCall(params.quote, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(_quoteDecimals));

        vm.prank(GOVERNOR);
        oracle.govSetConfig(params);
        oracle.setPrice(price);

        uint256 outAmount = oracle.getQuote(inAmount, params.base, params.quote);
        uint256 expectedOutAmount =
            params.inverse ? (inAmount * 10 ** _quoteDecimals) / price : (inAmount * price) / 10 ** _baseDecimals;
        assertEq(outAmount, expectedOutAmount);
    }

    function test_GetQuotes_RevertsWhen_NoConfig(uint256 inAmount, address base, address quote) public {
        vm.expectRevert(abi.encodeWithSelector(Errors.EOracle_NotSupported.selector, base, quote));
        oracle.getQuotes(inAmount, base, quote);
    }

    function test_GetQuotes_Integrity(
        RedstoneCoreOracle.ConfigParams memory params,
        uint8 _baseDecimals,
        uint8 _quoteDecimals,
        uint256 inAmount,
        uint256 price
    ) public {
        inAmount = bound(inAmount, 1, type(uint128).max);
        price = bound(price, 1, type(uint128).max);
        _baseDecimals = uint8(bound(_baseDecimals, 0, 27));
        _quoteDecimals = uint8(bound(_quoteDecimals, 0, 27));
        params.base = boundAddr(params.base);
        params.quote = boundAddr(params.quote);
        vm.assume(params.base != params.quote);
        vm.assume(params.feedId != 0);
        vm.mockCall(params.base, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(_baseDecimals));
        vm.mockCall(params.quote, abi.encodeWithSelector(ERC20.decimals.selector), abi.encode(_quoteDecimals));

        vm.prank(GOVERNOR);
        oracle.govSetConfig(params);
        oracle.setPrice(price);

        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, params.base, params.quote);
        uint256 expectedOutAmount =
            params.inverse ? (inAmount * 10 ** _quoteDecimals) / price : (inAmount * price) / 10 ** _baseDecimals;
        assertEq(bidOutAmount, expectedOutAmount);
        assertEq(askOutAmount, expectedOutAmount);
    }
}
