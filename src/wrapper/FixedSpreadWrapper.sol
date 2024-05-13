// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title FixedSpreadWrapper
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adds a fixed spread to the bid/ask quotes.
contract FixedSpreadWrapper is IPriceOracle {
    /// @inheritdoc IPriceOracle
    string public constant name = "FixedSpreadWrapper";
    /// @notice The denominator for `spreadMultiplier`.
    uint256 internal constant WAD = 1e18;
    /// @notice The address of the wrapped oracle.
    /// @dev Must implement IPriceOracle.
    address public immutable wrappedOracle;
    /// @notice The fixed spread, in 18-decimal fixed point (WAD).
    /// @dev 1.1e18 means 10% on each side, so ~20% total.
    uint256 public immutable spreadMultiplier;

    /// @notice Deploy a FixedSpreadWrapper.
    /// @param _wrappedOracle The address of the wrapped oracle.
    /// @param _spreadMultiplier The spread multiplier in WAD units.
    constructor(address _wrappedOracle, uint256 _spreadMultiplier) {
        if (spreadMultiplier <= WAD) revert Errors.PriceOracle_InvalidConfiguration();
        wrappedOracle = _wrappedOracle;
        spreadMultiplier = _spreadMultiplier;
    }

    /// @notice Return the result from the wrapped oracle unchanged.
    /// @inheritdoc IPriceOracle
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return IPriceOracle(wrappedOracle).getQuote(inAmount, base, quote);
    }

    /// @notice Return the result from the wrapped oracle with the fixed spread added.
    /// @inheritdoc IPriceOracle
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        (uint256 bidOutAmount, uint256 askOutAmount) = IPriceOracle(wrappedOracle).getQuotes(inAmount, base, quote);

        bidOutAmount = FixedPointMathLib.fullMulDiv(bidOutAmount, WAD, spreadMultiplier);
        askOutAmount = FixedPointMathLib.fullMulDivUp(askOutAmount, spreadMultiplier, WAD);
        return (bidOutAmount, askOutAmount);
    }
}
