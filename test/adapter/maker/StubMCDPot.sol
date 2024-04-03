// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IPot} from "src/adapter/maker/IPot.sol";

contract StubMCDPot is IPot {
    uint256 _chi;
    uint256 _rho;
    uint256 _dsr;
    bool doRevert;
    string revertMsg = "oops";

    function setRevert(bool _doRevert) external {
        doRevert = _doRevert;
    }

    function setParams(uint256 chi_, uint256 rho_, uint256 dsr_) external {
        _chi = chi_;
        _rho = rho_;
        _dsr = dsr_;
    }

    function chi() external view returns (uint256) {
        if (doRevert) revert(revertMsg);
        return _chi;
    }

    function rho() external view returns (uint256) {
        if (doRevert) revert(revertMsg);
        return _rho;
    }

    function dsr() external view returns (uint256) {
        if (doRevert) revert(revertMsg);
        return _dsr;
    }
}
