// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {HourglassOracle} from "src/adapter/hourglass/HourglassOracle.sol";
import {IHourglassDepositor} from "src/adapter/hourglass/IHourglassDepositor.sol";

contract HourglassOracleHelper is AdapterHelper {
    struct FuzzableState {
        // Config
        address base;
        address quote;
        uint256 discountRate;
        // Market Assets
        address depositor;
        address pt;
        address ct;
        address pyt;
        address underlyingToken;
        // Market State
        uint256 expiry;
        uint256 underlyingTokenBalance;
        uint256 ptSupply;
        uint256 ctSupply;
        // Environment
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);
        s.discountRate = bound(s.discountRate, 0, type(uint128).max);
        s.depositor = boundAddr(s.depositor);
        s.pt = boundAddr(s.pt);
        s.ct = boundAddr(s.ct);
        s.pyt = boundAddr(s.pyt);
        s.underlyingToken = boundAddr(s.underlyingToken);

        s.underlyingTokenBalance = bound(s.underlyingTokenBalance, 0, type(uint128).max);
        s.ptSupply = bound(s.ptSupply, 0, type(uint128).max);
        s.ctSupply = bound(s.ctSupply, 0, type(uint128).max);


        vm.assume(distinct(s.base, s.quote, s.depositor, s.pt, s.ct, s.pyt, s.underlyingToken));
        vm.assume(s.base != s.quote);

        s.expiry = bound(s.expiry, 0, block.timestamp);

        // Mock the Hourglass Depositor
        vm.mockCall(
            address(s.depositor),
            abi.encodeWithSelector(IHourglassDepositor.getTokens.selector),
            abi.encode(s.ct, s.pt, s.pyt) // Use s.ct, s.pt, and s.pyt for the tokens   
        );

        vm.mockCall(
            address(s.depositor),
            abi.encodeWithSelector(IHourglassDepositor.getUnderlying.selector),
            abi.encode(s.underlyingToken) // Use s.underlyingToken for the underlyingToken
        );

        vm.mockCall(
            address(s.depositor),
            abi.encodeWithSelector(IHourglassDepositor.maturity.selector),
            abi.encode(s.expiry) // Use s.expiry for the maturity time
        );

        // Mock the Principal Token
        vm.mockCall(
            address(s.pt),
            abi.encodeWithSelector(IERC20.totalSupply.selector),
            abi.encode(s.ptSupply) 
        );

        // Mock the Combined Token
        vm.mockCall(
            address(s.ct),
            abi.encodeWithSelector(IERC20.totalSupply.selector),
            abi.encode(s.ctSupply) 
        );

        // Mock the Underlying Token
        vm.mockCall(
            address(s.underlyingToken),
            abi.encodeWithSelector(IERC20.balanceOf.selector, address(s.depositor)),
            abi.encode(s.underlyingTokenBalance)
        );

        oracle = address(new HourglassOracle(s.base, s.quote, s.discountRate));
        s.inAmount = bound(s.inAmount, 0, type(uint128).max);
    }
}
