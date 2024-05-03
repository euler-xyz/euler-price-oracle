// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title OracleWithBackup
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Use a backup oracle if the priamry reverts.
contract OracleWithBackup is IPriceOracle {
    /// @inheritdoc IPriceOracle
    string public constant name = "OracleWithBackup";
    /// @notice The address of the primary oracle.
    address public immutable primaryOracle;
    /// @notice The address of the backup oracle.
    address public immutable backupOracle;

    /// @notice Deploy an OracleWithFallback.
    /// @param _primaryOracle The primary oracle.
    /// @param _backupOracle The fallback oracle to use if the primary fails.
    constructor(address _primaryOracle, address _backupOracle) {
        primaryOracle = _primaryOracle;
        backupOracle = _backupOracle;
    }

    /// @inheritdoc IPriceOracle
    /// @dev Calls `backupOracle` if `primaryOracle` reverts.
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        bytes memory getQuoteData = abi.encodeCall(IPriceOracle.getQuote, (inAmount, base, quote));
        (bool success, bytes memory data) = primaryOracle.staticcall(getQuoteData);
        if (success) return abi.decode(data, (uint256));

        (success, data) = backupOracle.staticcall(getQuoteData);
        if (success) return abi.decode(data, (uint256));
        revert Errors.PriceOracle_InvalidAnswer();
    }

    /// @inheritdoc IPriceOracle
    /// @dev Calls `backupOracle` if `primaryOracle` reverts.
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        bytes memory getQuotesData = abi.encodeCall(IPriceOracle.getQuotes, (inAmount, base, quote));
        (bool success, bytes memory data) = primaryOracle.staticcall(getQuotesData);
        if (success) return abi.decode(data, (uint256, uint256));

        (success, data) = backupOracle.staticcall(getQuotesData);
        if (success) return abi.decode(data, (uint256, uint256));
        revert Errors.PriceOracle_InvalidAnswer();
    }
}
