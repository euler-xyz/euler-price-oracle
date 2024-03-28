// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {StubOracleFactory} from "test/StubOracleFactory.sol";
import {OracleMultiFactory} from "src/OracleMultiFactory.sol";
import {Errors} from "src/lib/Errors.sol";

contract OracleMultiFactoryTest is Test {
    address GOVERNOR = makeAddr("GOVERNOR");
    OracleMultiFactory multiFactory;

    function setUp() public {
        multiFactory = new OracleMultiFactory(GOVERNOR);
    }

    function test_SetFactoryStatus_Integrity(address factory, bool isEnabled) public {
        vm.expectEmit();
        emit OracleMultiFactory.FactoryStatusSet(factory, isEnabled);
        vm.prank(GOVERNOR);
        multiFactory.setFactoryStatus(factory, isEnabled);

        assertEq(multiFactory.enabledFactories(factory), isEnabled);
    }

    function test_SetFactoryStatus_Integrity_Overwrite(address factory) public {
        vm.startPrank(GOVERNOR);
        multiFactory.setFactoryStatus(factory, true);
        assertTrue(multiFactory.enabledFactories(factory));

        multiFactory.setFactoryStatus(factory, false);
        assertFalse(multiFactory.enabledFactories(factory));

        multiFactory.setFactoryStatus(factory, true);
        assertTrue(multiFactory.enabledFactories(factory));
    }

    function test_SetFactoryStatus_RevertsWhen_CallerNotGovernor(address caller, address factory, bool isEnabled)
        public
    {
        vm.assume(caller != GOVERNOR);
        vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
        vm.prank(caller);
        multiFactory.setFactoryStatus(factory, isEnabled);
    }

    function test_SetSingletonOracle_Integrity(address base, address quote, address oracle) public {
        vm.expectEmit();
        emit OracleMultiFactory.SingletonOracleSet(oracle, base, quote);
        vm.prank(GOVERNOR);
        multiFactory.setSingletonOracle(base, quote, oracle);

        (address _factory, address _base, address _quote, bytes memory _extraData) =
            multiFactory.deployedOracles(oracle);

        assertEq(_factory, address(0));
        assertEq(_base, base);
        assertEq(_quote, quote);
        assertEq(_extraData.length, 0);
    }

    function test_SetSingletonOracle_RevertsWhen_CallerNotGovernor(
        address caller,
        address base,
        address quote,
        address oracle
    ) public {
        vm.assume(caller != GOVERNOR);
        vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
        vm.prank(caller);
        multiFactory.setSingletonOracle(base, quote, oracle);
    }

    function test_DeployWithFactory_Integrity(address base, address quote, bytes calldata extraData, address oracle)
        public
    {
        vm.assume(oracle != address(0));

        StubOracleFactory factory = new StubOracleFactory();
        factory.setDeploymentAddress(oracle);

        vm.prank(GOVERNOR);
        multiFactory.setFactoryStatus(address(factory), true);

        vm.expectEmit();
        emit OracleMultiFactory.OracleDeployed(oracle, address(factory), base, quote, extraData);

        address deployedOracle = multiFactory.deployWithFactory(address(factory), base, quote, extraData);
        assertEq(deployedOracle, oracle);

        (address _factory, address _base, address _quote, bytes memory _extraData) =
            multiFactory.deployedOracles(oracle);
        assertEq(_factory, address(factory));
        assertEq(_base, base);
        assertEq(_quote, quote);
        assertEq(keccak256(_extraData), keccak256(extraData));
    }

    function test_DeployWithFactory_RevertsWhen_FactoryReturnsAddressZero(
        address base,
        address quote,
        bytes calldata extraData
    ) public {
        StubOracleFactory factory = new StubOracleFactory();
        factory.setDeploymentAddress(address(0));

        vm.prank(GOVERNOR);
        multiFactory.setFactoryStatus(address(factory), true);

        vm.expectRevert(Errors.OracleMultiFactory_DeploymentFailed.selector);
        multiFactory.deployWithFactory(address(factory), base, quote, extraData);
    }

    function test_DeployWithFactory_RevertsWhen_FactoryUnauthorized(
        address factory,
        address base,
        address quote,
        bytes calldata extraData
    ) public {
        vm.expectRevert(Errors.OracleMultiFactory_FactoryUnauthorized.selector);
        multiFactory.deployWithFactory(factory, base, quote, extraData);
    }
}
