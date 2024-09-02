// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {Errors} from "../lib/Errors.sol";

/// @title BackupAggregator
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Use a backup oracle if the priamry reverts.
contract BackupAggregator is IPriceOracle {
    /// @inheritdoc IPriceOracle
    string public constant name = "BackupAggregator";
    /// @notice The address of the oracle to try first.
    address public immutable firstOracle;
    /// @notice The address of the oracle to try if the first oracle reverts.
    address public immutable secondOracle;
    /// @notice The address of the oracle to try if the second oracle reverts.
    address public immutable thirdOracle;
    /// @notice The gas limit for oracle calls.
    uint256 internal constant CALL_GAS = 500_000;

    /// @notice Deploy an OracleWithFallback.
    /// @param _firstOracle The address of the oracle to try first.
    /// @param _secondOracle The address of the oracle to try if the first oracle reverts.
    /// @param _thirdOracle The address of the oracle to try if the second oracle reverts.
    constructor(address _firstOracle, address _secondOracle, address _thirdOracle) {
        firstOracle = _firstOracle;
        secondOracle = _secondOracle;
        thirdOracle = _thirdOracle;
    }

    /// @inheritdoc IPriceOracle
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        // Encode the call.
        bytes memory getQuoteData = abi.encodeCall(IPriceOracle.getQuote, (inAmount, base, quote));

        // Try the first oracle.
        (bool success, bytes memory data) = tryCall(firstOracle, getQuoteData);
        if (success) return abi.decode(data, (uint256));

        // Try the second oracle.
        if (secondOracle == address(0)) revert Errors.PriceOracle_InvalidAnswer();
        (success, data) = tryCall(secondOracle, getQuoteData);
        if (success) return abi.decode(data, (uint256));

        // Try the third oracle.
        if (thirdOracle == address(0)) revert Errors.PriceOracle_InvalidAnswer();
        (success, data) = tryCall(thirdOracle, getQuoteData);
        if (success) return abi.decode(data, (uint256));

        // All calls were unsuccessful.
        revert Errors.PriceOracle_InvalidAnswer();
    }

    /// @inheritdoc IPriceOracle
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        // Encode the call.
        bytes memory getQuotesData = abi.encodeCall(IPriceOracle.getQuotes, (inAmount, base, quote));

        // Try the first oracle.
        (bool success, bytes memory data) = tryCall(firstOracle, getQuotesData);
        if (success) return abi.decode(data, (uint256, uint256));

        // Try the second oracle.
        if (secondOracle == address(0)) revert Errors.PriceOracle_InvalidAnswer();
        (success, data) = tryCall(secondOracle, getQuotesData);
        if (success) return abi.decode(data, (uint256, uint256));

        // Try the third oracle.
        if (thirdOracle == address(0)) revert Errors.PriceOracle_InvalidAnswer();
        (success, data) = tryCall(thirdOracle, getQuotesData);
        if (success) return abi.decode(data, (uint256, uint256));

        // All calls were unsuccessful.
        revert Errors.PriceOracle_InvalidAnswer();
    }

    /// @notice Attempt to call an oracle.
    /// @param oracle The address of the oracle to call.
    /// @param data The data for the call.
    /// @dev Will not revert if the call reverts.
    /// @return The call result: true if successful, false if revert.
    /// @return The return data of the call.
    function tryCall(address oracle, bytes memory data) internal view returns (bool, bytes memory) {
        return oracle.staticcall{gas: CALL_GAS}(data);
    }
}
