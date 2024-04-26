// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title LowHighOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Combines the answers of two PriceOracles.
contract LowHighOracle is IPriceOracle {
    /// @notice The address of the first oracle.
    address public immutable oracleA;
    /// @notice The address of the second oracle.
    address public immutable oracleB;

    /// @notice Deploy a LowHighOracle.
    /// @param _oracleA The address of the first oracle.
    /// @param _oracleB The address of the second oracle.
    constructor(address _oracleA, address _oracleB) {
        oracleA = _oracleA;
        oracleB = _oracleB;
    }

    /// @notice Return the average of quotes from `oracleA` and `oracleB`.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @dev If either oracle reverts, return the quote from the other oracle.
    /// @return The outAmount.
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        (bool successA, bool successB, uint256 outAmountA, uint256 outAmountB) = _tryGetQuote(inAmount, base, quote);

        if (successA && successB) return (outAmountA + outAmountB) / 2; // Both succeeded, return the average.
        if (successA) return outAmountA; // `oracleA` succeeded only, return its quote.
        if (successB) return outAmountB; // `oracleA` succeeded only, return its quote.=
        revert Errors.PriceOracle_InvalidAnswer();
    }

    /// @notice Return the average of quotes from `oracleA` and `oracleB`.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @dev If either oracle reverts, return the quote from the other oracle.
    /// @return The outAmount.
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        (bool successA, bool successB, uint256 outAmountA, uint256 outAmountB) = _tryGetQuote(inAmount, base, quote);

        if (successA && successB) {
            // Both succeeded, sort the quotes and return the them.
            (uint256 outAmountLow, uint256 outAmountHigh) =
                outAmountA < outAmountB ? (outAmountA, outAmountB) : (outAmountB, outAmountA);
            return (outAmountLow, outAmountHigh);
        }
        if (successA) return (outAmountA, outAmountA); // Only `oracleA` succeeded, return its quote twice.
        if (successB) return (outAmountB, outAmountB); // Only `oracleB` succeeded, return its quote twice.
        revert Errors.PriceOracle_InvalidAnswer(); // Neither oracles succeeded, revert.
    }

    function _tryGetQuote(uint256 inAmount, address base, address quote)
        internal
        view
        returns (bool, bool, uint256, uint256)
    {
        bytes memory getQuoteData = abi.encodeCall(IPriceOracle.getQuote, (inAmount, base, quote));
        (bool successA, bytes memory dataA) = oracleA.staticcall(getQuoteData);
        (bool successB, bytes memory dataB) = oracleB.staticcall(getQuoteData);

        uint256 outAmountA = successA ? abi.decode(dataA, (uint256)) : 0;
        uint256 outAmountB = successB ? abi.decode(dataB, (uint256)) : 0;
        return (successA, successB, outAmountA, outAmountB);
    }
}
