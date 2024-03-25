// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IReth} from "src/adapter/rocketpool/IReth.sol";

contract StubReth is IReth {
    uint256 rate;
    bool doRevert;
    string revertMsg = "oops";

    function setRate(uint256 _rate) external {
        rate = _rate;
    }

    function setRevert(bool _doRevert) external {
        doRevert = _doRevert;
    }

    function getRethValue(uint256 x) external view returns (uint256) {
        if (doRevert) revert(revertMsg);
        return x * 1e18 / rate;
    }

    function getEthValue(uint256 x) external view returns (uint256) {
        if (doRevert) revert(revertMsg);
        return x * rate / 1e18;
    }
}
