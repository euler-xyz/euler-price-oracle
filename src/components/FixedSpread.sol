// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";

/// @title FixedSpread
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adds a fixed spread to the bid/ask quotes.
contract FixedSpread is IPriceOracle {
    /// @notice The address of the wrapped oracle or adapter.
    address public immutable wrapped;

    /// @notice The fixed spread, in 18-decimal fixed point. IE: 0.1e18 means 10% (on each side, so ~20% total)
    uint256 public immutable spread;

    /// @notice Deploy a FixedSpread oracle.
    /// @param _wrapped The address of the wrapped oracle.
    /// @param _spread The spread
    constructor(address _wrapped, uint256 _spread) {
        wrapped = _wrapped;
        spread = _spread;
    }

    /// @notice Return the result from the wrapped oracle unchanged.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @return The outAmount.
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return IPriceOracle(wrapped).getQuote(inAmount, base, quote);
    }

    /// @notice Return the result from the wrapped oracle with the fixed spread added.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced.
    /// @param quote The token that is the unit of account.
    /// @return The outAmount.
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        (uint256 bidOutAmount, uint256 askOutAmount) = IPriceOracle(wrapped).getQuotes(inAmount, base, quote);

        uint256 spreadMultiplier = spread + 1e18;

        return (bidOutAmount * 1e18 / spreadMultiplier, askOutAmount * spreadMultiplier / 1e18);
    }
}
