// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {console2} from "forge-std/console2.sol";

contract StubERC4626 {
    address public immutable asset;
    uint256 private rate;
    string revertMsg = "oops";
    bool doRevert;

    constructor(address _asset, uint256 _rate) {
        asset = _asset;
        rate = _rate;
    }

    function setRevert(bool _doRevert) external {
        doRevert = _doRevert;
    }

    function setRate(uint256 _rate) external {
        rate = _rate;
    }

    function convertToAssets(uint256 shares) external view returns (uint256) {
        if (doRevert) revert(revertMsg);
        console2.log("convertToAssets", shares, rate);
        return shares * rate / 1e18;
    }

    function convertToShares(uint256 assets) external view returns (uint256) {
        if (doRevert) revert(revertMsg);
        console2.log("convertToShares", assets, rate);
        return assets * 1e18 / rate;
    }
}
