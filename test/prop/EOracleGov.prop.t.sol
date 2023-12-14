// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {IFactoryInitializable} from "src/interfaces/IFactoryInitializable.sol";

abstract contract EOracleGovPropTest is Test {
    IFactoryInitializable internal oracle;

    function setUp() public {
        oracle = IFactoryInitializable(_deployOracle());
    }

    function statefulFuzz_Initialize_Integrity() public {
        address _governor = makeAddr("governor");
        bool _initialized = oracle.initialized();

        if (!_initialized) {
            oracle.initialize(_governor);
            assertEq(oracle.governor(), _governor);
        } else {
            vm.expectRevert(IFactoryInitializable.AlreadyInitialized.selector);
            oracle.initialize(_governor);
        }
    }

    function statefulFuzz_TransferGovernance_AccessControl() public {
        address newGovernor = makeAddr("newGovernor");

        address currentGovernor = oracle.governor();
        if (msg.sender != currentGovernor) {
            vm.expectRevert(IFactoryInitializable.CallerNotGovernor.selector);
            oracle.transferGovernance(newGovernor);
        } else {
            oracle.transferGovernance(newGovernor);
            assertEq(oracle.governor(), newGovernor);
        }
    }

    function statefulFuzz_TransferGovernance_Integrity() public {
        address newGovernor = makeAddr("newGovernor");

        vm.prank(oracle.governor());
        oracle.transferGovernance(newGovernor);
        assertEq(oracle.governor(), newGovernor);
    }

    function statefulFuzz_RenounceGovernance_AccessControl() public {
        vm.prank(oracle.governor());
        oracle.renounceGovernance();

        assertEq(oracle.governor(), address(0));
    }

    function statefulFuzz_RenounceGovernance_Integrity() public {
        vm.prank(oracle.governor());
        oracle.renounceGovernance();
        assertEq(oracle.governor(), address(0));
    }

    function statefulFuzz_CannotBeBothFinalizedAndGoverned() public {
        bool _finalized = oracle.finalized();
        bool _governed = oracle.governed();

        assertFalse(_finalized && _governed);
    }

    function _deployOracle() internal virtual returns (address);

    function _govMethods() internal pure virtual returns (bytes4[] memory) {
        return new bytes4[](0);
    }
}
