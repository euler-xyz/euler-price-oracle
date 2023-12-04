// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {ConstantOracle2, ConstantOracle2Upgraded} from "test/factory/ConstantOracle2.sol";
import {ParentOracle, ParentOracle2, ChildOracle} from "test/factory/NestedOracle.sol";
import {OracleFactory} from "src/factory/OracleFactory.sol";

contract GenericFactoryTest is Test {
    function test_deployAndUpgrade() public {
        address admin = address(10000);
        address base = address(10001);
        address quote = address(10002);

        OracleFactory factory = new OracleFactory(admin);

        ConstantOracle2 oracleImpl = new ConstantOracle2();

        vm.prank(admin);
        factory.setImplementation(address(oracleImpl));

        ConstantOracle2 deploymentUpgradeable = ConstantOracle2(factory.activate(true, base, quote));
        _verifyProxying(deploymentUpgradeable, base, quote);

        ConstantOracle2 deploymentNonupgradeable = ConstantOracle2(factory.activate(false, base, quote));
        _verifyProxying(deploymentNonupgradeable, base, quote);

        ConstantOracle2Upgraded oracleImplUpgraded = new ConstantOracle2Upgraded();
        vm.prank(admin);
        factory.setImplementation(address(oracleImplUpgraded));

        assertEq(deploymentUpgradeable.hey(), 2);
        assertEq(deploymentNonupgradeable.hey(), 1);
    }

    // function test_nested() public {
    //     address admin = address(10000);
    //     address base = address(10001);
    //     address quote = address(10002);

    //     OracleFactory parentFactory = new OracleFactory(admin);
    //     ParentOracle parentImpl = new ParentOracle();
    //     vm.prank(admin);
    //     parentFactory.setImplementation(address(parentImpl));

    //     OracleFactory childFactory = new OracleFactory(admin);
    //     ChildOracle childImpl = new ChildOracle();
    //     vm.prank(admin);
    //     childFactory.setImplementation(address(childImpl));

    //     ChildOracle childUp = ChildOracle(childFactory.activate(true, base, address(100)));
    //     ParentOracle parentUp = ParentOracle(parentFactory.activate(true, base, address(childUp)));
    //     assertEq(parentUp.getQuote(1, base, quote), 300);
    //     assertEq(childUp.getQuote(1, base, quote), 100);

    //     ParentOracle2 parent2Up = new ParentOracle2();
    //     vm.prank(admin);
    //     parentFactory.setImplementation(address(parent2Up));

    //     assertEq(parentUp.getQuote(1, base, quote), 500);
    //     assertEq(childUp.getQuote(1, base, quote), 100);
    // }

    function _verifyProxying(ConstantOracle2 deployment, address _base, address _quote) private {
        uint256 outAmount = deployment.getQuote(5 ether, _base, _quote);
        assertEq(outAmount, 5 ether);

        vm.expectRevert();
        deployment.getQuote(5 ether, _quote, _base);
    }
}
