// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IPyth} from "@pyth/IPyth.sol";
import {PythStructs} from "@pyth/PythStructs.sol";
import {StubPyth} from "test/adapter/pyth/StubPyth.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {PythOracle} from "src/adapter/pyth/PythOracle.sol";

contract PythOracleHelper is Test {
    address PYTH;

    struct FuzzableConfig {
        address base;
        address quote;
        bytes32 feedId;
        uint256 maxStaleness;
        uint8 baseDecimals;
        uint8 quoteDecimals;
    }

    function _bound(PythStructs.Price memory p) internal pure {
        p.price = int64(bound(p.price, 1, type(int64).max));
        p.conf = uint64(bound(p.conf, 0, uint64(p.price) / 20));
        p.expo = int32(bound(p.expo, -16, 16));
    }

    function _deploy(FuzzableConfig memory c) internal returns (PythOracle) {
        PYTH = address(new StubPyth());
        c.base = boundAddr(c.base);
        c.quote = boundAddr(c.quote);
        vm.assume(c.base != c.quote && c.base != PYTH && c.quote != PYTH);
        c.baseDecimals = uint8(bound(c.baseDecimals, 0, 18));
        c.quoteDecimals = uint8(bound(c.quoteDecimals, 0, 18));
        c.maxStaleness = uint32(bound(c.maxStaleness, 0, type(uint32).max));
        vm.mockCall(c.base, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(c.baseDecimals));
        vm.mockCall(c.quote, abi.encodeWithSelector(IERC20.decimals.selector), abi.encode(c.quoteDecimals));
        return new PythOracle(PYTH, c.base, c.quote, c.feedId, c.maxStaleness);
    }
}
