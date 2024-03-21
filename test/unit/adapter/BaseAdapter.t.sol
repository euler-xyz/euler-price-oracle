// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {BaseAdapter, Errors} from "src/adapter/BaseAdapter.sol";

contract StubAdapter is BaseAdapter {
    function _getQuote(uint256, address, address) internal pure override returns (uint256) {
        return 0;
    }

    function getDecimals(address token) external view returns (uint8) {
        return _getDecimals(token);
    }
}

contract BaseAdapterTest is Test {
    StubAdapter oracle;

    function setUp() public {
        oracle = new StubAdapter();
    }

    function test_GetDecimals_RevertsWhen_AddressZero() public {
        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        oracle.getDecimals(address(0));
    }

    function test_GetDecimals_RevertsWhen_CallReverts(address x) public {
        x = boundAddr(x);
        vm.mockCallRevert(x, abi.encodeWithSelector(IERC20.decimals.selector), "oops");

        vm.expectRevert(Errors.PriceOracle_InvalidConfiguration.selector);
        oracle.getDecimals(x);
    }

    function test_GetDecimals_Integrity_ISO4217(uint256 _x) public view {
        address x = address(uint160(bound(_x, 1, 999)));

        uint8 decimals = oracle.getDecimals(x);
        assertEq(decimals, 18);
    }

    function test_GetDecimals_Integrity_ERC20(address x, uint8 decimals) public {
        x = boundAddr(x);
        vm.mockCall(x, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(decimals));

        uint8 _decimals = oracle.getDecimals(x);
        assertEq(_decimals, decimals);
    }
}
