// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {ERC4626} from "@solady/tokens/ERC4626.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {ERC4626Oracle} from "src/adapter/erc4626/ERC4626Oracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract ERC4626OracleTest is Test {
    address internal VAULT = makeAddr("VAULT");
    address internal ASSET = makeAddr("ASSET");

    ERC4626Oracle oracle;

    function setUp() public {
        vm.mockCall(VAULT, abi.encodeWithSelector(ERC4626.asset.selector), abi.encode(ASSET));
        oracle = new ERC4626Oracle(VAULT);
    }

    function test_Constructor_Integrity() public view {
        assertEq(oracle.vault(), VAULT);
        assertEq(oracle.asset(), ASSET);
    }

    function test_Constructor_RevertsWhen_AssetCallFails() public {
        vm.mockCallRevert(VAULT, abi.encodeWithSelector(ERC4626.asset.selector), "oops");
        vm.expectRevert(abi.encodePacked("oops"));
        oracle = new ERC4626Oracle(VAULT);
    }

    function test_GetQuote_Integrity_SharesToAssets(uint256 inAmount, uint256 outAmount) public {
        vm.mockCall(VAULT, abi.encodeWithSelector(ERC4626.convertToAssets.selector, inAmount), abi.encode(outAmount));
        assertEq(oracle.getQuote(inAmount, VAULT, ASSET), outAmount);
    }

    function test_GetQuote_Integrity_AssetsToShares(uint256 inAmount, uint256 outAmount) public {
        vm.mockCall(VAULT, abi.encodeWithSelector(ERC4626.convertToShares.selector, inAmount), abi.encode(outAmount));
        assertEq(oracle.getQuote(inAmount, ASSET, VAULT), outAmount);
    }

    function test_GetQuote_RevertsWhen_InvalidAsset(uint256 inAmount, address asset) public {
        vm.assume(asset != ASSET);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, asset, VAULT));
        oracle.getQuote(inAmount, asset, VAULT);
    }

    function test_GetQuote_RevertsWhen_InvalidShare(uint256 inAmount, address vault) public {
        vm.assume(vault != VAULT);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, ASSET, vault));
        oracle.getQuote(inAmount, ASSET, vault);
    }

    function test_GetQuotes_Integrity_SharesToAssets(uint256 inAmount, uint256 outAmount) public {
        vm.mockCall(VAULT, abi.encodeWithSelector(ERC4626.convertToAssets.selector, inAmount), abi.encode(outAmount));
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, VAULT, ASSET);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
    }

    function test_GetQuotes_Integrity_AssetsToShares(uint256 inAmount, uint256 outAmount) public {
        vm.mockCall(VAULT, abi.encodeWithSelector(ERC4626.convertToShares.selector, inAmount), abi.encode(outAmount));
        (uint256 bidOutAmount, uint256 askOutAmount) = oracle.getQuotes(inAmount, ASSET, VAULT);
        assertEq(bidOutAmount, outAmount);
        assertEq(askOutAmount, outAmount);
    }

    function test_GetQuotes_RevertsWhen_InvalidAsset(uint256 inAmount, address asset) public {
        vm.assume(asset != ASSET);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, asset, VAULT));
        oracle.getQuotes(inAmount, asset, VAULT);
    }

    function test_GetQuotes_RevertsWhen_InvalidShare(uint256 inAmount, address vault) public {
        vm.assume(vault != VAULT);
        vm.expectRevert(abi.encodeWithSelector(Errors.PriceOracle_NotSupported.selector, ASSET, vault));
        oracle.getQuotes(inAmount, ASSET, vault);
    }
}
