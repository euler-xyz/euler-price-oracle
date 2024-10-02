// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.10;

/// @title IIdleTranche
/// @author Idle DAO (https://github.com/Idle-Labs/idle-tranches/blob/master/contracts/interfaces/IIdleCDO.sol)
/// @notice Partial interface for Idle Tranches.
interface IIdleTranche {
    /// @notice The address of the IIdleCDO.
    function minter() external view returns (address);
}
