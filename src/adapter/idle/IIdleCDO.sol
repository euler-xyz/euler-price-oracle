// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.8.10;

/// @title IIdleCDO
/// @author Idle DAO (https://github.com/Idle-Labs/idle-tranches/blob/master/contracts/interfaces/IIdleCDO.sol)
/// @notice Partial interface for Idle Tranches.
interface IIdleCDO {
    /// @notice The address of the underlying token.
    function token() external view returns (address);

    /// @notice The price of 1 tranche in underlying, so eg 1 xxUSDC tranche in USDC.
    /// @param _tranche The address of the tranche.
    /// @return The price of 1 tranche in underlying.
    function virtualPrice(address _tranche) external view returns (uint256);
}
