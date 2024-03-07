// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {GovEOracle} from "src/GovEOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title FallbackRouter
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Oracle resolver with a configurable mapping and optional fallback.
contract FallbackRouter is GovEOracle {
    /// @notice The EOracle to call if this router is not configured for base/quote.
    /// @dev If `address(0)` then there is no fallback.
    address public fallbackOracle;
    /// @notice EOracle configured for base/quote.
    mapping(address base => mapping(address quote => address)) public oracles;

    /// @notice Configure an EOracle to resolve base/quote.
    /// @param base The address of the base token.
    /// @param quote The address of the quote token.
    /// @param oracle The address of the EOracle that resolves base/quote.
    /// @dev If `oracle` is `address(0)` then the base/quote configuration was removed.
    event ConfigSet(address indexed base, address indexed quote, address indexed oracle);
    /// @notice Set an EOracle as a fallback resolver.
    /// @param fallbackOracle The address of the EOracle that is called when base/quote is not configured.
    /// @dev If `fallbackOracle` is `address(0)` then there is no fallback resolver.
    event FallbackOracleSet(address indexed fallbackOracle);

    /// @notice Deploy FallbackRouter.
    /// @param _fallbackOracle The EOracle to call if base/quote is not configured.
    /// @dev If `_fallbackOracle` is `address(0)` then do not use a fallback.
    constructor(address _fallbackOracle) {
        fallbackOracle = _fallbackOracle;
        emit FallbackOracleSet(_fallbackOracle);
    }

    /// @notice Configure an EOracle to resolve base/quote.
    /// @param base The address of the base token.
    /// @param quote The address of the quote token.
    /// @param oracle The address of the EOracle that resolves base/quote.
    /// @dev Callable only by the governor.
    function govSetConfig(address base, address quote, address oracle) external onlyGovernor {
        oracles[base][quote] = oracle;
        emit ConfigSet(base, quote, oracle);
    }

    /// @notice Clear the configuration for base/quote.
    /// @param base The address of the base token.
    /// @param quote The address of the quote token.
    /// @dev Callable only by the governor.
    function govClearConfig(address base, address quote) external onlyGovernor {
        delete oracles[base][quote];
        emit ConfigSet(base, quote, address(0));
    }

    /// @notice Set an EOracle as a fallback resolver.
    /// @param _fallbackOracle The address of the EOracle that is called when base/quote is not configured.
    /// @dev `address(0)` removes the fallback.
    function govSetFallbackOracle(address _fallbackOracle) external onlyGovernor {
        fallbackOracle = _fallbackOracle;
        emit FallbackOracleSet(_fallbackOracle);
    }

    /// @inheritdoc IEOracle
    /// @dev Calls the configured oracle for the path. If no oracle is configured,
    /// calls `fallbackOracle` or reverts if `fallbackOracle` is not set.
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        address oracle = _resolveOracle(base, quote);
        return IEOracle(oracle).getQuote(inAmount, base, quote);
    }

    /// @inheritdoc IEOracle
    /// @dev Calls the configured oracle for the path. If no oracle is configured,
    /// calls `fallbackOracle` or reverts if `fallbackOracle` is not set.
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        address oracle = _resolveOracle(base, quote);
        return IEOracle(oracle).getQuotes(inAmount, base, quote);
    }

    /// @notice Resolve the EOracle to call for a given base/quote pair.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @dev First check the oracles mapping, then check if there is a fallback oracle.
    /// @return The EOracle to call.
    function _resolveOracle(address base, address quote) internal view returns (address) {
        address oracle = oracles[base][quote];
        if (oracle == address(0)) oracle = fallbackOracle;
        if (oracle == address(0)) revert Errors.EOracle_NotSupported(base, quote);
        return oracle;
    }
}
