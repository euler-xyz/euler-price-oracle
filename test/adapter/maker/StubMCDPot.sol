// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IPot} from "src/adapter/maker/IPot.sol";

contract StubMCDPot is IPot {
    uint256 public chi;

    function setRate(uint256 _chi) external {
        chi = _chi;
    }
}
