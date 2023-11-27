// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {BaseOracle} from "src/BaseOracle.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author totomanov
/// @notice Optimized oracle resolver for base-quote pairs.
/// Supports up to 4 base assets against the same quote asset and an optional fallback oracle.
/// @dev Uses `ImmutableAddressArray` to save on SLOADs.
contract ImmutableRouter is BaseOracle, ImmutableAddressArray {
    address public immutable quote;
    address public immutable fallbackOracle;

    /// @notice Deploy a new ImmutableRouter.
    /// @param _quote The single quote asset supported by the router.
    /// @param _baseOraclePairs Up to 4 base-oracle pairs.
    /// @param _fallbackOracle Optional oracle to fallback to if the route is not configured.
    /// @dev Base-oracle pairs are interleaved with bases at even indices (2k)
    /// and corresponding oracles at adjacent odd indices (2k+1).
    constructor(address _quote, address[] memory _baseOraclePairs, address _fallbackOracle)
        ImmutableAddressArray(_baseOraclePairs)
    {
        uint256 length = _baseOraclePairs.length;
        if (length < 2) revert Errors.Router_MalformedPairs(length);
        if (length % 2 != 0) revert Errors.Arity2Mismatch(length / 2, length / 2 + 1);
        quote = _quote;
        fallbackOracle = _fallbackOracle;
    }

    /// @inheritdoc IPriceOracle
    /// @dev Reverts if the quote asset is different from the one configured at deployment.
    function getQuote(uint256 inAmount, address base, address _quote) external view override returns (uint256) {
        if (_quote != quote) revert Errors.PriceOracle_NotSupported(base, _quote);
        address oracle = _getOracle(base);
        return IPriceOracle(oracle).getQuote(inAmount, base, quote);
    }

    /// @inheritdoc IPriceOracle
    /// @dev Reverts if the quote asset is different from the one configured at deployment.
    function getQuotes(uint256 inAmount, address base, address _quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        if (_quote != quote) revert Errors.PriceOracle_NotSupported(base, _quote);
        address oracle = _getOracle(base);
        return IPriceOracle(oracle).getQuotes(inAmount, base, quote);
    }

    /// @notice Get the corresponding oracle address for a given base
    /// from the immutable address array.
    /// @param base The base to search for
    /// @dev Base assets are found at even indices (2k) and corresponding
    /// oracles are found at adjacent odd indices (2k+1).
    /// Reverts iff no oracle was found and fallback oracle is not set.
    /// Calling function MUST check that the quote asset is valid.
    /// @return The oracle to use for `base`
    function _getOracle(address base) private view returns (address) {
        uint256 index = _arrayFind(base);
        if (index == type(uint256).max) {
            if (fallbackOracle == address(0)) {
                revert Errors.PriceOracle_NotSupported(base, quote);
            }
            return fallbackOracle;
        }
        address oracle = _arrayGet(index + 1);
        if (oracle == address(0)) {
            if (fallbackOracle == address(0)) {
                revert Errors.PriceOracle_NotSupported(base, quote);
            }
            return fallbackOracle;
        }
        return oracle;
    }

    /// @inheritdoc IPriceOracle
    function description() external pure override returns (OracleDescription.Description memory) {
        return OracleDescription.ImmutableRouter();
    }
}
