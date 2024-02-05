// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {GovEOracle} from "src/GovEOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @title SimpleRouter
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Oracle resolver for base-quote pairs.
contract SimpleRouter is GovEOracle {
    address public fallbackOracle;
    mapping(address base => mapping(address quote => address)) public oracles;

    event ConfigSet(address indexed base, address indexed quote, address indexed oracle);
    event FallbackOracleSet(address indexed fallbackOracle);

    constructor(address _fallbackOracle) {
        fallbackOracle = _fallbackOracle;
    }

    function govSetConfig(address base, address quote, address oracle) external onlyGovernor {
        oracles[base][quote] = oracle;
        emit ConfigSet(base, quote, oracle);
    }

    function govUnsetConfig(address base, address quote) external onlyGovernor {
        delete oracles[base][quote];
        emit ConfigSet(base, quote, address(0));
    }

    function govSetFallbackOracle(address _fallbackOracle) external onlyGovernor {
        fallbackOracle = _fallbackOracle;
        emit FallbackOracleSet(_fallbackOracle);
    }

    /// @inheritdoc IEOracle
    /// @dev Calls the configured oracle for the path. If no oracle is configured, call `fallbackOracle`
    /// or reverts if `fallbackOracle` is not set.
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        address oracle = _resolveOracle(base, quote);
        return IEOracle(oracle).getQuote(inAmount, base, quote);
    }

    /// @inheritdoc IEOracle
    /// @dev Calls the configured oracle for the path. If no oracle is configured, call `fallbackOracle`
    /// or reverts if `fallbackOracle` is not set.
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        address oracle = _resolveOracle(base, quote);
        return IEOracle(oracle).getQuotes(inAmount, base, quote);
    }

    /// @inheritdoc IEOracle
    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.SimpleRouter(governor);
    }

    function _resolveOracle(address base, address quote) internal view returns (address) {
        address oracle = oracles[base][quote];
        if (oracle == address(0)) oracle = fallbackOracle;
        if (oracle == address(0)) revert Errors.EOracle_NotSupported(base, quote);
        return oracle;
    }
}
