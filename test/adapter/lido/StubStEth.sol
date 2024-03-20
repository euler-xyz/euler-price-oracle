// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IStEth} from "src/adapter/lido/IStEth.sol";

contract StubStEth is IStEth {
    uint256 rate;

    function setRate(uint256 _rate) external {
        rate = _rate;
    }

    function getPooledEthByShares(uint256 x) external view returns (uint256) {
        return x * rate / 1e18;
    }

    function getSharesByPooledEth(uint256 x) external view returns (uint256) {
        return x * 1e18 / rate;
    }
}
