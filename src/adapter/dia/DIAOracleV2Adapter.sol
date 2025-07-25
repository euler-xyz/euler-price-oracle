// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {IDIAOracleV2} from "./IDIAOracleV2.sol";
import {ScaleUtils, Scale} from "../../lib/ScaleUtils.sol";

/// @title DIAOracleV2Adapter
/// @notice PriceOracle adapter for DIA Oracle V2 price feeds.
contract DIAOracleV2Adapter is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "DIAOracleV2Adapter";
    /// @notice The minimum permitted value for `maxStaleness`.
    uint256 internal constant MAX_STALENESS_LOWER_BOUND = 1 minutes;
    /// @notice The maximum permitted value for `maxStaleness`.
    uint256 internal constant MAX_STALENESS_UPPER_BOUND = 72 hours;
    /// @notice The address of the base asset corresponding to the feed.
    address public immutable base;
    /// @notice The address of the quote asset corresponding to the feed.
    address public immutable quote;
    /// @notice The address of the DIA Oracle V2 contract.
    address public immutable oracle;
    /// @notice The key used to fetch the price from DIA Oracle.
    string public feedKey;
    /// @notice The maximum allowed age of the price.
    /// @dev Reverts if block.timestamp - updatedAt > maxStaleness.
    uint256 public immutable maxStaleness;
    /// @notice The scale factors used for decimal conversions.
    Scale internal immutable scale;

    /// @notice Deploy a DIAOracleV2Adapter.
    /// @param _base The address of the base asset corresponding to the feed.
    /// @param _quote The address of the quote asset corresponding to the feed.
    /// @param _oracle The address of the DIA Oracle V2 contract.
    /// @param _feedKey The key used to fetch the price from DIA Oracle (e.g., "ETH/USD").
    /// @param _maxStaleness The maximum allowed age of the price.
    /// @param _feedDecimals The number of decimals in the DIA price feed.
    constructor(
        address _base,
        address _quote,
        address _oracle,
        string memory _feedKey,
        uint256 _maxStaleness,
        uint8 _feedDecimals
    ) {
        if (_maxStaleness < MAX_STALENESS_LOWER_BOUND || _maxStaleness > MAX_STALENESS_UPPER_BOUND) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        base = _base;
        quote = _quote;
        oracle = _oracle;
        feedKey = _feedKey;
        maxStaleness = _maxStaleness;

        // The scale factor is used to correctly convert decimals.
        uint8 baseDecimals = _getDecimals(base);
        uint8 quoteDecimals = _getDecimals(quote);
        
        // Validate decimals to prevent overflow (same check as in ScaleUtils)
        if (quoteDecimals > 38 || _feedDecimals + baseDecimals > 38) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }
        
        scale = ScaleUtils.calcScale(baseDecimals, quoteDecimals, _feedDecimals);
    }

    /// @notice Get the quote from the DIA Oracle V2 feed.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the DIA Oracle feed.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        (uint128 value, uint128 timestamp) = IDIAOracleV2(oracle).getValue(feedKey);
        
        if (value == 0) revert Errors.PriceOracle_InvalidAnswer();
        
        uint256 staleness = block.timestamp - timestamp;
        if (staleness > maxStaleness) revert Errors.PriceOracle_TooStale(staleness, maxStaleness);

        uint256 price = uint256(value);
        return ScaleUtils.calcOutAmount(inAmount, price, scale, inverse);
    }
}