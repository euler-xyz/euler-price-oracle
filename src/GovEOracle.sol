// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {IFactoryInitializable} from "src/interfaces/IFactoryInitializable.sol";

/// @title GovEOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Governable mixin.
abstract contract GovEOracle is IEOracle, IFactoryInitializable {
    address public governor;
    bool public initialized;

    /// @inheritdoc IFactoryInitializable
    function initialize(address _governor) external {
        if (initialized) revert Errors.Governance_AlreadyInitialized();
        initialized = true;
        _setGovernor(_governor);
    }

    /// @inheritdoc IFactoryInitializable
    function transferGovernance(address newGovernor) external onlyGovernor {
        _setGovernor(newGovernor);
    }

    /// @inheritdoc IFactoryInitializable
    function renounceGovernance() external onlyGovernor {
        _setGovernor(address(0));
    }

    /// @inheritdoc IFactoryInitializable
    function finalized() external view returns (bool) {
        return initialized && governor == address(0);
    }

    /// @inheritdoc IFactoryInitializable
    function governed() external view returns (bool) {
        return initialized && governor != address(0);
    }

    /// @notice Set the governor address.
    /// @param newGovernor The address of the new governor.
    function _setGovernor(address newGovernor) private {
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernorSet(oldGovernor, newGovernor);
    }

    /// @notice Restrict access to the governor.
    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert Errors.Governance_CallerNotGovernor();
        }
        _;
    }
}
