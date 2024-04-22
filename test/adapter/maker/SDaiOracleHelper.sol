// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {SDaiOracle} from "src/adapter/maker/SDaiOracle.sol";
import {StubERC4626} from "test/StubERC4626.sol";
import {AdapterHelper} from "test/adapter/AdapterHelper.sol";
import {DAI, SDAI} from "test/utils/EthereumAddresses.sol";

contract SDaiOracleHelper is AdapterHelper {
    struct FuzzableState {
        uint256 rate;
        uint256 inAmount;
    }

    function setUpState(FuzzableState memory s) internal {
        s.rate = bound(s.rate, 1e18, 1e27);
        s.inAmount = bound(s.inAmount, 1, type(uint128).max);

        oracle = address(new SDaiOracle());
        vm.etch(SDAI, address(new StubERC4626(DAI, s.rate)).code);

        StubERC4626(SDAI).setRate(s.rate);

        if (behaviors[Behavior.FeedReverts]) {
            StubERC4626(SDAI).setRevert(true);
        }
    }
}
