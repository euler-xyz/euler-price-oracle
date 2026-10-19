// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC4626} from "forge-std/interfaces/IERC4626.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr} from "test/utils/TestUtils.sol";
import {StubERC4626} from "test/StubERC4626.sol";
import {ERC4626Oracle} from "src/adapter/erc4626/ERC4626Oracle.sol";

contract ERC4626OracleHelper is AdapterHelper {
    struct FuzzableState {
        // Config
        address base;
        address quote;
        // Oracle State
        uint256 rate;
        // Environment
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.base = boundAddr(s.base);
        s.quote = boundAddr(s.quote);

        vm.assume(s.base != s.quote);

        s.rate = bound(s.rate, 1e9, 1e27);

        vm.etch(s.base, address(new StubERC4626(s.quote, 0)).code);

        StubERC4626(s.base).setRate(s.rate);
        StubERC4626(s.base).setRevert(behaviors[Behavior.FeedReverts]);

        oracle = address(new ERC4626Oracle(s.base));
        s.inAmount = bound(s.inAmount, 0, type(uint128).max);
    }
}
