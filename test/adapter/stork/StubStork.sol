// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {StorkStructs} from "../../../src/adapter/stork/IStork.sol";


contract StubStork {
    StorkStructs.TemporalNumericValue value;
    bool doRevert;
    string revertMsg = "oops";

    function setPrice(StorkStructs.TemporalNumericValue memory _value) external {
        value = _value;
    }

    function setRevert(bool _doRevert) external {
        doRevert = _doRevert;
    }

    function getTemporalNumericValueUnsafeV1(
        bytes32
    ) external view returns (StorkStructs.TemporalNumericValue memory) {
        if (doRevert) revert(revertMsg);
        return value;
    }
}
