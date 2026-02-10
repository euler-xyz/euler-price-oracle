// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {HourglassOracle} from "src/adapter/hourglass/HourglassOracle.sol";
import {IHourglassDepositor} from "src/adapter/hourglass/IHourglassDepositor.sol";
import "forge-std/console.sol";

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
        bool baseIsPt;
    }

    function setUpState(FuzzableState memory s) internal {
        // Set reasonable bounds for addresses
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);
        s.depositor = boundAddr(s.depositor);
        s.pt = boundAddr(s.pt);
        s.ct = boundAddr(s.ct);
        s.pyt = boundAddr(s.pyt);
        s.underlyingToken = boundAddr(s.underlyingToken);

        // Set reasonable bounds for numeric values
        // Minimum could be near zero, or something like 1e8 (≈ ~0.000003% annual)
        // Maximum ~3.17e10 for ~100% annual
        s.discountRate = bound(s.discountRate, 1, 3.2e10);
        s.underlyingTokenBalance = bound(s.underlyingTokenBalance, 0, 1e24);

        // Ensure ptSupply and ctSupply add up to underlyingTokenBalance
        uint256 maxSupply = s.underlyingTokenBalance;
        s.ptSupply = bound(s.ptSupply, 0, s.underlyingTokenBalance);
        s.ctSupply = s.underlyingTokenBalance - s.ptSupply;

        s.expiry = bound(s.expiry, block.timestamp, block.timestamp + 365 days);
        s.inAmount = bound(s.inAmount, 0, 1e18);

        console.log("s.base: %s", s.base);
        console.log("s.quote: %s", s.quote);
        console.log("s.depositor: %s", s.depositor);
        console.log("s.pt: %s", s.pt);
        console.log("s.ct: %s", s.ct);
        console.log("s.pyt: %s", s.pyt);
        console.log("s.underlyingToken: %s", s.underlyingToken);
        console.log("s.discountRate: %s", s.discountRate);
        console.log("s.underlyingTokenBalance: %s", s.underlyingTokenBalance);
        console.log("s.ptSupply: %s", s.ptSupply);
        console.log("s.ctSupply: %s", s.ctSupply);
        console.log("s.expiry: %s", s.expiry);
        console.log("s.inAmount: %s", s.inAmount);

        // Assume distinct addresses
        vm.assume(distinct(s.quote, s.depositor, s.pt, s.ct, s.pyt, s.underlyingToken));
        s.base = s.baseIsPt ? s.pt : s.ct;

        // Prepare the dynamic array
        address[] memory tokens = new address[](3);
        tokens[0] = s.ct;
        tokens[1] = s.pt;
        tokens[2] = s.pyt;

        // Then encode *that array* in the mock
        vm.mockCall(
            s.depositor,
            abi.encodeWithSelector(IHourglassDepositor.getTokens.selector),
            abi.encode(tokens) // This is the correct way to encode a dynamic array
        );

        vm.mockCall(
            s.depositor,
            abi.encodeWithSelector(IHourglassDepositor.getUnderlying.selector),
            abi.encode(s.underlyingToken)
        );

        vm.mockCall(s.depositor, abi.encodeWithSelector(IHourglassDepositor.maturity.selector), abi.encode(s.expiry));

        // Mock the Principal Token
        vm.mockCall(s.pt, abi.encodeWithSelector(IERC20.totalSupply.selector), abi.encode(s.ptSupply));

        // Mock the Combined Token
        vm.mockCall(s.ct, abi.encodeWithSelector(IERC20.totalSupply.selector), abi.encode(s.ctSupply));

        // Mock the Underlying Token
        vm.mockCall(
            s.underlyingToken,
            abi.encodeWithSelector(IERC20.balanceOf.selector, s.depositor),
            abi.encode(s.underlyingTokenBalance)
        );

        // ========== NEW: Mock the TBT (the "base") calls ==========

        // 1) The constructor calls HourglassERC20TBT(_base).depositor()
        vm.mockCall(
            s.base,
            abi.encodeWithSelector(bytes4(keccak256("depositor()"))), // or HourglassERC20TBT.depositor.selector
            abi.encode(s.depositor)
        );

        // 2) The constructor calls HourglassERC20TBT(_base).decimals()
        vm.mockCall(
            s.base,
            abi.encodeWithSelector(bytes4(keccak256("decimals()"))), // or HourglassERC20TBT.decimals.selector
            abi.encode(uint8(18)) // or whatever decimals you want to simulate
        );

        // 3) The constructor also calls _getDecimals(s.quote) internally
        //    If your adapter or base code does "IERC20Metadata(_quote).decimals()",
        //    you might need to mock that if 's.quote' doesn't implement decimals().
        vm.mockCall(
            s.quote,
            abi.encodeWithSelector(bytes4(keccak256("decimals()"))),
            abi.encode(uint8(18)) // or a different decimal count if needed
        );

        // Now actually deploy the oracle:
        oracle = address(new HourglassOracle(s.base, s.quote, s.discountRate));

        HourglassOracle hourglassOracle = HourglassOracle(oracle);
        console.log("oracle dr: %s", hourglassOracle.discountRate()); // Re-bound s.inAmount to some smaller range if needed
        s.inAmount = bound(s.inAmount, 0, type(uint128).max);
    }
}
