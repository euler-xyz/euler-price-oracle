// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {IFactoryInitializable} from "src/interfaces/IFactoryInitializable.sol";

abstract contract GovEOracle is IEOracle, IFactoryInitializable {
    address public override governor;
    bool public override initialized;

    function initialize(address _governor) external override {
        if (initialized) revert Errors.Governance_AlreadyInitialized();
        initialized = true;
        _setGovernor(_governor);
    }

    function transferGovernance(address newGovernor) external override onlyGovernor {
        _setGovernor(newGovernor);
    }

    function renounceGovernance() external override onlyGovernor {
        _setGovernor(address(0));
    }

    function finalized() external view override returns (bool) {
        return initialized && governor == address(0);
    }

    function governed() external view override returns (bool) {
        return initialized && governor != address(0);
    }

    function _setGovernor(address newGovernor) private {
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernorSet(oldGovernor, newGovernor);
    }

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert Errors.Governance_CallerNotGovernor();
        }
        _;
    }
}
