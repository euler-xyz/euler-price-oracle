// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseOracle} from "src/BaseOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author totomanov
/// @notice Oracle resolver for base-quote pairs.
contract SimpleRouter is BaseOracle {
    IEOracle public fallbackOracle;
    mapping(address base => mapping(address quote => IEOracle)) public oracles;

    /// @inheritdoc IEOracle
    /// @dev Calls the configured oracle for the path. If no oracle is configured, call `fallbackOracle`
    /// or reverts if `fallbackOracle` is not set.
    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        IEOracle oracle = oracles[base][quote];
        if (address(oracle) == address(0)) oracle = fallbackOracle;
        if (address(oracle) == address(0)) revert Errors.EOracle_NotSupported(base, quote);
        return oracle.getQuote(inAmount, base, quote);
    }

    /// @inheritdoc IEOracle
    /// @dev Calls the configured oracle for the path. If no oracle is configured, call `fallbackOracle`
    /// or reverts if `fallbackOracle` is not set.
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        IEOracle oracle = oracles[base][quote];
        if (address(oracle) == address(0)) oracle = fallbackOracle;
        if (address(oracle) == address(0)) revert Errors.EOracle_NotSupported(base, quote);
        return oracle.getQuotes(inAmount, base, quote);
    }

    /// @inheritdoc IEOracle
    function description() external pure override returns (OracleDescription.Description memory) {
        return OracleDescription.SimpleRouter();
    }

    /// @inheritdoc BaseOracle
    function _initializeOracle(bytes memory _data) internal override {
        (address[] memory _bases, address[] memory _quotes, address[] memory _oracles, address _fallbackOracle) =
            abi.decode(_data, (address[], address[], address[], address));

        if (_bases.length != _quotes.length || _quotes.length != _oracles.length) {
            revert Errors.Arity3Mismatch(_bases.length, _quotes.length, _oracles.length);
        }

        uint256 length = _bases.length;
        for (uint256 i = 0; i < length;) {
            address base = _bases[i];
            address quote = _quotes[i];
            address oracle = _oracles[i];
            oracles[base][quote] = IEOracle(oracle);

            unchecked {
                ++i;
            }
        }
        fallbackOracle = IEOracle(_fallbackOracle);
    }
}
