// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {ScaleUtils, Scale} from "../../lib/ScaleUtils.sol";

/// @title OndoOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
contract OndoOracle is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "OndoOracle";
    /// @notice The address of the base asset corresponding to the rate provider.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the rate provider.
    address public immutable quote;
    /// @notice The address of the Ondo Redemption Oracle contract.
    address public immutable redemptionOracle;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy a RateProviderOracle.
    /// @param _base The address of the base asset corresponding to the Rate Provider.
    /// @param _quote The address of the quote asset corresponding to the Rate Provider.
    /// @param _redemptionOracle The address of the Ondo Redemption Oracle contract.
    constructor(address _base, address _quote, address _redemptionOracle) {
        base = _base;
        quote = _quote;
        redemptionOracle = _redemptionOracle;
        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);
        // Ondo Redemption Oracles return an 18-decimal fixed-point value.
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, 18);
    }

    /// @notice Get the quote from the Ondo Redemption Oracle.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the Ondo Redemption Oracle.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);
        uint256 price = IOndoRWAOracle(redemptionOracle).getPrice();
        if (price == 0) revert Errors.PriceOracle_InvalidAnswer();
        return ScaleUtils.calcOutAmount(inAmount, price, scale, inverse);
    }
}

interface IOndoRWAOracle {
    function getPrice() external view returns (uint256);
}