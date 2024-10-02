// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {boundAddr, distinct} from "test/utils/TestUtils.sol";
import {IdleTranchesOracle} from "src/adapter/idle/IdleTranchesOracle.sol";
import {IIdleCDO} from "src/adapter/idle/IIdleCDO.sol";
import {IIdleTranche} from "src/adapter/idle/IIdleTranche.sol";

contract IdleTranchesOracleHelper is AdapterHelper {
    struct FuzzableState {
        // Config
        address cdo;
        address tranche;
        address underlying;
        // Oracle State
        uint256 virtualPrice;
        // Environment
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.cdo = boundAddr(s.cdo);
        s.tranche = boundAddr(s.tranche);
        s.underlying = boundAddr(s.underlying);

        vm.assume(distinct(s.cdo, s.tranche, s.underlying));

        if (behaviors[Behavior.FeedReturnsZeroPrice]) {
            s.virtualPrice = 0;
        } else {
            s.virtualPrice = bound(s.virtualPrice, 1, type(uint128).max);
        }

        if (behaviors[Behavior.FeedReverts]) {
            vm.mockCallRevert(s.cdo, abi.encodeCall(IIdleCDO.virtualPrice, (s.tranche)), "");
        } else {
            vm.mockCall(s.cdo, abi.encodeCall(IIdleCDO.virtualPrice, (s.tranche)), abi.encode(s.virtualPrice));
        }

        vm.mockCall(s.cdo, abi.encodeCall(IIdleCDO.token, ()), abi.encode(s.underlying));
        vm.mockCall(s.tranche, abi.encodeCall(IIdleTranche.minter, ()), abi.encode(s.cdo));

        oracle = address(new IdleTranchesOracle(s.cdo, s.tranche));
        s.inAmount = bound(s.inAmount, 0, type(uint128).max);
    }
}
