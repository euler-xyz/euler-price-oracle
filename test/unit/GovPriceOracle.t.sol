// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {GovPriceOracle} from "src/GovPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";

contract TestOracle is GovPriceOracle {
    function getQuote(uint256, address, address) external pure returns (uint256) {}
    function getQuotes(uint256, address, address) external pure returns (uint256, uint256) {}
}

contract GovPriceOracleTest is Test {
    TestOracle internal oracle;

    function setUp() public {
        oracle = new TestOracle();
    }

    function statefulFuzz_Initialize_Integrity() public {
        address _governor = makeAddr("governor");
        bool _initialized = oracle.initialized();

        if (!_initialized) {
            oracle.initialize(_governor);
            assertEq(oracle.governor(), _governor);
        } else {
            vm.expectRevert(Errors.Governance_AlreadyInitialized.selector);
            oracle.initialize(_governor);
        }
    }

    function test_TransferGovernance_AccessControl(address caller, address governor, address newGovernor) public {
        oracle.initialize(governor);

        if (caller == governor) {
            vm.prank(caller);
            oracle.transferGovernance(newGovernor);
            assertEq(oracle.governor(), newGovernor);
        } else {
            vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
            vm.prank(caller);
            oracle.transferGovernance(newGovernor);
        }
    }

    function statefulFuzz_TransferGovernance_Integrity() public {
        address newGovernor = makeAddr("newGovernor");

        vm.prank(oracle.governor());
        oracle.transferGovernance(newGovernor);
        assertEq(oracle.governor(), newGovernor);
    }

    function test_RenounceGovernance_AccessControl(address caller, address governor) public {
        oracle.initialize(governor);

        if (caller == governor) {
            vm.prank(caller);
            oracle.renounceGovernance();
            assertEq(oracle.governor(), address(0));
        } else {
            vm.expectRevert(Errors.Governance_CallerNotGovernor.selector);
            vm.prank(caller);
            oracle.renounceGovernance();
        }
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
}
