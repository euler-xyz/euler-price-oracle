// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ExecutionContext, EC} from "ethereum-vault-connector/ExecutionContext.sol";

contract StubEVCAuth {
    using ExecutionContext for EC;

    EC executionContext;
    address a;
    mapping(address accountOwner => address) owners;

    function getRawExecutionContext() external view returns (uint256) {
        return EC.unwrap(executionContext);
    }

    function setCurrentOnBehalfOfAccount(address _a) external {
        a = _a;
    }

    function getCurrentOnBehalfOfAccount(address) external view returns (address, bool) {
        require(a != address(0), "OnBehalfOfAccountNotAuthenticated");
        return (a, false);
    }

    function setAccountOwner(address account, address owner) external {
        owners[account] = owner;
    }

    function getAccountOwner(address account) external view returns (address owner) {
        return owners[account];
    }

    function setControlCollateralInProgress(bool inProgress) external {
        if (inProgress) {
            executionContext = executionContext.setControlCollateralInProgress();
        } else {
            executionContext =
                EC.wrap(EC.unwrap(executionContext) & ~uint256(0xFF00000000000000000000000000000000000000000000));
        }
    }

    function setChecksInProgress(bool inProgress) external {
        if (inProgress) {
            executionContext = executionContext.setChecksInProgress();
        } else {
            executionContext =
                EC.wrap(EC.unwrap(executionContext) & ~uint256(0xFF000000000000000000000000000000000000000000));
        }
    }

    function setOperatorAuthenticated(bool authenticated) external {
        if (authenticated) {
            executionContext = executionContext.setOperatorAuthenticated();
        } else {
            executionContext = executionContext.clearOperatorAuthenticated();
        }
    }

    function makeCall(address to, bytes calldata data) external {
        (bool success,) = to.call(data);
        require(success);
    }
}
