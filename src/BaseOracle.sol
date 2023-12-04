// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IEOracle} from "src/interfaces/IEOracle.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

abstract contract BaseOracle is IEOracle {
    address public governor;
    bool public initialized;

    error AlreadyInitialized();
    error CallerNotGovernor();
    error CannotInitializeToZeroAddress();

    event GovernorSet(address indexed oldGovernor, address indexed newGovernor);

    function initialize(address _governor, bytes memory _data) external {
        if (initialized) revert AlreadyInitialized();
        _setGovernor(_governor);
        initialized = true;

        _initializeOracle(_data);
    }

    function transferGovernance(address newGovernor) external onlyGovernor {
        _setGovernor(newGovernor);
    }

    function renounceGovernance() external onlyGovernor {
        _setGovernor(address(0));
    }

    function finalized() external view returns (bool) {
        return initialized && governor == address(0);
    }

    function governed() external view returns (bool) {
        return initialized && governor != address(0);
    }

    function _initializeOracle(bytes memory _data) internal virtual;

    function _setGovernor(address newGovernor) private {
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernorSet(oldGovernor, newGovernor);
    }

    modifier onlyGovernor() {
        if (msg.sender != governor) {
            revert CallerNotGovernor();
        }
        _;
    }
}
