// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";
import {Test} from "forge-std/Test.sol";
import {DynamicBeaconProxy} from "src/factory/DynamicBeaconProxy.sol";

contract DynamicBeaconProxyTest is Test {
    function test_debugdbp() public {
        bytes memory trailingData = abi.encode(uint256(1023));
        console2.log("trailingData");
        console2.logBytes(trailingData);
        DynamicBeaconProxy proxy = new DynamicBeaconProxy(trailingData);

        bytes memory code = address(proxy).code;
        console2.log("code");
        console2.logBytes(code);
    }
}
