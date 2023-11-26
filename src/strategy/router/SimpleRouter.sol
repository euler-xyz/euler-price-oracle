// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author totomanov
/// @notice Oracle resolver for base-quote pairs.
contract SimpleRouter is IPriceOracle {
    IPriceOracle public immutable fallbackOracle;
    mapping(address base => mapping(address quote => IPriceOracle)) public oracles;

    /// @dev After construction paths are immutable.
    constructor(address[] memory _bases, address[] memory _quotes, address[] memory _oracles, address _fallbackOracle) {
        if (_bases.length != _quotes.length || _quotes.length != _oracles.length) {
            revert Errors.Arity3Mismatch(_bases.length, _quotes.length, _oracles.length);
        }

        uint256 length = _bases.length;
        for (uint256 i = 0; i < length;) {
            address base = _bases[i];
            address quote = _quotes[i];
            address oracle = _oracles[i];
            oracles[base][quote] = IPriceOracle(oracle);

            unchecked {
                ++i;
            }
        }
        fallbackOracle = IPriceOracle(_fallbackOracle);
    }

    /// @inheritdoc IPriceOracle
    /// @dev Calls the configured oracle for the path. If no oracle is configured, call `fallbackOracle`
    /// or reverts if `fallbackOracle` is not set.
    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        IPriceOracle oracle = oracles[base][quote];
        if (address(oracle) == address(0)) oracle = fallbackOracle;
        if (address(oracle) == address(0)) revert Errors.PriceOracle_NotSupported(base, quote);
        return oracle.getQuote(inAmount, base, quote);
    }

    /// @inheritdoc IPriceOracle
    /// @dev Calls the configured oracle for the path. If no oracle is configured, call `fallbackOracle`
    /// or reverts if `fallbackOracle` is not set.
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        IPriceOracle oracle = oracles[base][quote];
        if (address(oracle) == address(0)) oracle = fallbackOracle;
        if (address(oracle) == address(0)) revert Errors.PriceOracle_NotSupported(base, quote);
        return oracle.getQuotes(inAmount, base, quote);
    }

    /// @inheritdoc IPriceOracle
    function description() external pure override returns (OracleDescription.Description memory) {
        return OracleDescription.SimpleRouter();
    }
}
