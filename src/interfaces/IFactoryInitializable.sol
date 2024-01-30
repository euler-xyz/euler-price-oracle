// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

/// @title IFactoryInitializable
/// @author Euler Labs (https://www.eulerlabs.com/)
interface IFactoryInitializable {
    event GovernorSet(address indexed oldGovernor, address indexed newGovernor);

    function initialize(address _governor) external;
    function transferGovernance(address) external;
    function renounceGovernance() external;
    function initialized() external view returns (bool);
    function finalized() external view returns (bool);
    function governed() external view returns (bool);
    function governor() external view returns (address);
}
