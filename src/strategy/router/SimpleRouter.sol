// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseOracle} from "src/BaseOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author totomanov
/// @notice Oracle resolver for base-quote pairs.
contract SimpleRouter is BaseOracle {
    struct ConfigParams {
        address base;
        address quote;
        address oracle;
    }

    IEOracle public fallbackOracle;
    mapping(address base => mapping(address quote => IEOracle)) public oracles;

    constructor(ConfigParams[] memory _initialConfigs, address _fallbackOracle) {
        uint256 length = _initialConfigs.length;
        for (uint256 i = 0; i < length;) {
            ConfigParams memory params = _initialConfigs[i];
            oracles[params.base][params.quote] = IEOracle(params.oracle);

            unchecked {
                ++i;
            }
        }
        fallbackOracle = IEOracle(_fallbackOracle);
    }

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
}
