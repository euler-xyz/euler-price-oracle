// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {Test} from "forge-std/Test.sol";
import {EOracleHandler} from "test/prop/EOracleHandler.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {IFactoryInitializable} from "src/interfaces/IFactoryInitializable.sol";

abstract contract EOraclePropTest is Test {
    EOracleHandler internal handler;
    address internal oracle;

    function setUp() public {
        handler = new EOracleHandler(_deployOracle());
        oracle = handler.oracle();

        targetContract(address(handler));
    }

    function invariantProp_Initialize_Integrity() public {
        address _governor = makeAddr("governor");
        bool _initialized = IFactoryInitializable(oracle).initialized();

        if (!_initialized) {
            IFactoryInitializable(oracle).initialize(_governor);
            assertEq(BaseOracle(oracle).governor(), _governor);
        } else {
            vm.expectRevert(IFactoryInitializable.AlreadyInitialized.selector);
            IFactoryInitializable(oracle).initialize(_governor);
        }
    }

    function invariantProp_CannotBeBothFinalizedAndGoverned() public {
        bool _finalized = BaseOracle(oracle).finalized();
        bool _governed = BaseOracle(oracle).governed();

        assertFalse(_finalized && _governed);
    }

    function invariantProp_OnlyGovernorCanTransferGovernance() public {
        address _governor = BaseOracle(oracle).governor();
        vm.prank(_governor);
        address newGovernor = makeAddr("newGovernor");
        BaseOracle(oracle).transferGovernance(newGovernor);

        assertEq(BaseOracle(oracle).governor(), newGovernor);
    }

    function invariantProp_GetQuote_NeverReturnsZero() public {
        (bool hasReturned, bytes memory value) = handler.returnCache(IEOracle.getQuote.selector);

        if (hasReturned) {
            uint256 outAmount = abi.decode(value, (uint256));
            assertGt(outAmount, 0);
        }
    }

    function invariantProp_GetQuotes_NeverReturnsZero() public {
        (bool hasReturned, bytes memory value) = handler.returnCache(IEOracle.getQuotes.selector);

        if (hasReturned) {
            (uint256 bid, uint256 ask) = abi.decode(value, (uint256, uint256));
            assertGt(bid, 0);
            assertGt(ask, 0);
        }
    }

    function _deployOracle() internal virtual returns (address);
}
