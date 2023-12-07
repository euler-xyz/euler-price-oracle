// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

interface IFactoryInitializable {
    error AlreadyInitialized();
    error CallerNotGovernor();
    error CannotInitializeToZeroAddress();

    function initialize(address _governor) external;
    function initialized() external view returns (bool);
}
