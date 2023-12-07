// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {ConstantOracle2, ConstantOracle2Upgraded} from "test/factory/ConstantOracle2.sol";
import {ParentOracle, ParentOracle2, ChildOracle} from "test/factory/NestedOracle.sol";
import {OracleFactory} from "src/factory/OracleFactory.sol";

/// @dev Data locations
/// - creation-time immutables and logic is not handled by the factory per se,
/// rather they can be changed when deploying an upgraded implementation: needs `upgradeable=true`
/// Store data that is unlikely to change e.g. weth address, univ3 factory.
/// Cheaper runtime gas than `trailingData` since it is stored in contract code and also handled by optimizer.
/// - `trailingData` - this is the "immutable" metadata passed by concatenating it to calldata
/// Store data that is unlikely to change e.g. weth address, univ3 factory.
/// Slightly more expensive runtime than
/// - `initData` - bytes passed to `initialize`
/// Store data that is unlikely to change e.g. weth address, univ3 factory.
/// Slightly more expensive runtime than
contract GenericFactoryTest is Test {
    function test_deployAndUpgrade() public {
        address admin = address(0x10000);
        address base = address(0x10001);
        address quote = address(0x10002);

        OracleFactory factory = new OracleFactory(admin);

        ConstantOracle2 oracleImpl = new ConstantOracle2(777);

        vm.prank(admin);
        factory.setImplementation(address(oracleImpl));

        bytes memory trailingData = abi.encode(base, quote);

        ConstantOracle2 deploymentUpgradeable = ConstantOracle2(factory.deploy(true, trailingData));
        assertEq(deploymentUpgradeable.getQuote(5 ether, base, quote), 5 ether);
        assertEq(deploymentUpgradeable.immutableValue(), 777);
        assertEq(deploymentUpgradeable.hey(), 1);

        ConstantOracle2 deploymentNonupgradeable = ConstantOracle2(factory.deploy(false, trailingData));
        assertEq(deploymentNonupgradeable.getQuote(5 ether, base, quote), 5 ether);
        assertEq(deploymentNonupgradeable.immutableValue(), 777);
        assertEq(deploymentNonupgradeable.hey(), 1);

        ConstantOracle2Upgraded oracleImplUpgraded = new ConstantOracle2Upgraded(778);
        vm.prank(admin);
        factory.setImplementation(address(oracleImplUpgraded));

        assertEq(deploymentUpgradeable.getQuote(5 ether, base, quote), 5 ether);
        assertEq(deploymentUpgradeable.immutableValue(), 778);
        assertEq(deploymentUpgradeable.hey(), 2);

        assertEq(deploymentNonupgradeable.getQuote(5 ether, base, quote), 5 ether);
        assertEq(deploymentNonupgradeable.immutableValue(), 777);
        assertEq(deploymentNonupgradeable.hey(), 1);
    }

    function test_nested() public {
        address admin = address(10000);
        address base = address(10001);
        address quote = address(10002);

        OracleFactory parentFactory = new OracleFactory(admin);
        ParentOracle parentImpl = new ParentOracle();
        vm.prank(admin);
        parentFactory.setImplementation(address(parentImpl));

        OracleFactory childFactory = new OracleFactory(admin);
        ChildOracle childImpl = new ChildOracle();
        vm.prank(admin);
        childFactory.setImplementation(address(childImpl));

        ChildOracle childUp = ChildOracle(childFactory.deploy(true, abi.encode(base, address(100))));
        ParentOracle parentUp = ParentOracle(parentFactory.deploy(true, abi.encode(base, address(childUp))));
        assertEq(parentUp.getQuote(1, base, quote), 300);
        assertEq(childUp.getQuote(1, base, quote), 100);

        ParentOracle2 parent2Up = new ParentOracle2();
        vm.prank(admin);
        parentFactory.setImplementation(address(parent2Up));

        assertEq(parentUp.getQuote(1, base, quote), 500);
        assertEq(childUp.getQuote(1, base, quote), 100);
    }
}
