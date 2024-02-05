// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

/// @title IFactoryInitializable
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Interface for EOracles that are initializable by EFactory.
interface IFactoryInitializable {
    event GovernorSet(address indexed oldGovernor, address indexed newGovernor);

    /// @notice Initialize the EOracle.
    /// @param _governor The address of the initial governor.
    /// @dev Sets the governor. Can be called only once.
    function initialize(address _governor) external;
    /// @notice Set the address of the governor.
    /// @param newGovernor The address of the next governor.
    /// @dev Can only be called by the current governor.
    function transferGovernance(address newGovernor) external;
    /// @notice Remove the governor.
    /// @dev Sets governor to address(0), effectively removing governance.
    function renounceGovernance() external;
    /// @notice Check whether the contract has been initialized.
    /// @return Whether `initialize` has been called.
    function initialized() external view returns (bool);
    /// @notice Check whether the contract is immutable.
    /// @return Whether the contract is initialized and the governor role is renounced.
    function finalized() external view returns (bool);
    /// @notice Check whether the contract is governed.
    /// @return Whether the contract is initialized and the governor role is held.
    function governed() external view returns (bool);
    /// @notice Retrieve the active governor address.
    /// @return The address of the current governor.
    function governor() external view returns (address);
}
