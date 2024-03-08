// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC4626} from "@solady/tokens/ERC4626.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {ERC4626Oracle} from "src/adapter/erc4626/ERC4626Oracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract ERC4626OracleTest is Test {
    struct FuzzableConfig {
        address vault;
        address asset;
    }

    ERC4626Oracle oracle;

    function test_Constructor_Integrity(FuzzableConfig memory c) public {
        _deploy(c);
        assertEq(oracle.vault(), c.vault);
        assertEq(oracle.asset(), c.asset);
    }

    function test_GetQuote_Integrity_SharesToAssets(FuzzableConfig memory c, uint256 inAmount, uint256 outAmount)
        public
    {
        _deploy(c);
        vm.mockCall(c.vault, abi.encodeWithSelector(ERC4626.convertToAssets.selector, inAmount), abi.encode(outAmount));
        assertEq(oracle.getQuote(inAmount, c.vault, c.asset), outAmount);
    }

    function test_GetQuote_Integrity_AssetsToShares(FuzzableConfig memory c, uint256 inAmount, uint256 outAmount)
        public
    {
        _deploy(c);
        vm.mockCall(c.vault, abi.encodeWithSelector(ERC4626.convertToShares.selector, inAmount), abi.encode(outAmount));
        assertEq(oracle.getQuote(inAmount, c.asset, c.vault), outAmount);
    }

    function test_GetQuote_RevertsWhen_InvalidAsset(FuzzableConfig memory c, uint256 inAmount, address asset) public {
        _deploy(c);
        vm.assume(asset != c.asset);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, asset, c.vault));
        oracle.getQuote(inAmount, asset, c.vault);
    }

    function test_GetQuote_RevertsWhen_InvalidShare(FuzzableConfig memory c, uint256 inAmount, address vault) public {
        _deploy(c);
        vm.assume(vault != c.vault);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, c.asset, vault));
        oracle.getQuote(inAmount, c.asset, vault);
    }

    function test_GetQuotes_Integrity_SharesToAssets(FuzzableConfig memory c, uint256 inAmount, uint256 outAmount)
        public
    {
        _deploy(c);
        vm.mockCall(c.vault, abi.encodeWithSelector(ERC4626.convertToAssets.selector, inAmount), abi.encode(outAmount));
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.vault, c.asset);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
    }

    function test_GetQuotes_Integrity_AssetsToShares(FuzzableConfig memory c, uint256 inAmount, uint256 outAmount)
        public
    {
        _deploy(c);
        vm.mockCall(c.vault, abi.encodeWithSelector(ERC4626.convertToShares.selector, inAmount), abi.encode(outAmount));
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, c.asset, c.vault);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
    }

    function _deploy(FuzzableConfig memory c) private {
        c.vault = boundAddr(c.vault);
        c.asset = boundAddr(c.asset);
        vm.assume(c.vault != c.asset);

        vm.mockCall(c.vault, abi.encodeWithSelector(ERC4626.asset.selector), abi.encode(c.asset));

        oracle = new ERC4626Oracle(c.vault);
    }
}
