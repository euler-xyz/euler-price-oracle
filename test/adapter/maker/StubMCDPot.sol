// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IPot} from "src/adapter/maker/IPot.sol";

contract StubMCDPot is IPot {
    uint256 _chi;
    bool doRevert;
    string revertMsg = "oops";

    function setRevert(bool _doRevert) external {
        doRevert = _doRevert;
    }

    function setRate(uint256 chi_) external {
        _chi = chi_;
    }

    function chi() external view returns (uint256) {
        if (doRevert) revert(revertMsg);
        return _chi;
    }
}
