// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ChainlinkInfrequentOracle, IPriceOracle, Errors} from "./ChainlinkInfrequentOracle.sol";

interface IBackedAutoFeeToken {
    function multiplierUpdatesLength() external view returns (uint256);
    function multiplierUpdates(uint256 index)
        external
        view
        returns (uint256 previousMultiplier, uint256 newMultiplier, uint256 activationTime);
}

/// @title ChainlinkInfrequentXStocksOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice PriceOracle adapter for Chainlink push-based price feeds and xStocks rebasing tokens.
/// @dev The oracle reverts when a multiplier update with a relative change >= maxAllowedMultiplierChange
/// is within [activationTime - pauseTimeBefore, activationTime + pauseTimeAfter].
/// If there are multiple updates within the time window, each of them are checked separately, they are
/// not analyzed cumulatively. Updates scheduled in short intervals, each below the allowed max multiplier change
/// could cumulatively exceed the limit without triggering a pause.
contract ChainlinkInfrequentXStocksOracle is ChainlinkInfrequentOracle {
    /// @notice The oracle is paused due to a multiplier change.
    error PriceOracle_MultiplierUpdatePause();

    /// @notice Time bracket to pause before the multiplier update in seconds.
    uint256 public immutable pauseTimeBefore;
    /// @notice Time bracket to pause after the multiplier update in seconds.
    uint256 public immutable pauseTimeAfter;
    /// @notice Max relative multiplier change allowed without pausing (WAD).
    uint256 public immutable maxAllowedMultiplierChange;
    /// @notice Address of the xStocks rebasing token
    address public immutable xStocksToken;

    /// @notice Deploy a ChainlinkOracle.
    /// @param _pauseTimeBefore Time bracket to pause before the multiplier update in seconds.
    /// @param _pauseTimeAfter Time bracket to pause after the multiplier update in seconds.
    /// @param _maxAllowedMultiplierChange Max relative multiplier change allowed without pausing (WAD).
    /// Note that if set to >= 1 WAD, the decrease of modifier will never trigger a pause (can't reduce more than 100%)
    /// @param _xStocksToken Address of the xStocks rebasing token.
    /// @param _base The address of the xStocks base asset corresponding to the feed.
    /// @param _quote The address of the quote asset corresponding to the feed.
    /// @param _feed The address of the Chainlink price feed.
    /// @param _maxStaleness The maximum allowed age of the price.
    /// @dev Consider setting `_maxStaleness` to slightly more than the feed's heartbeat
    /// to account for possible network delays when the heartbeat is triggered.
    constructor(
        uint256 _pauseTimeBefore,
        uint256 _pauseTimeAfter,
        uint256 _maxAllowedMultiplierChange,
        address _xStocksToken,
        address _base,
        address _quote,
        address _feed,
        uint256 _maxStaleness
    ) ChainlinkInfrequentOracle(_base, _quote, _feed, _maxStaleness) {
        if (_xStocksToken != _base && _xStocksToken != _quote) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }

        pauseTimeBefore = _pauseTimeBefore;
        pauseTimeAfter = _pauseTimeAfter;
        maxAllowedMultiplierChange = _maxAllowedMultiplierChange;
        xStocksToken = _xStocksToken;
    }

    /// @notice Get the quote from the Chainlink feed. Revert if xStocks token changes multiplier.
    /// @param inAmount The amount of `base` to convert.
    /// @param _base The token that is being priced.
    /// @param _quote The token that is the unit of account.
    /// @return The converted amount using the Chainlink feed.
    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        _checkMultiplierUpdates();
        return super._getQuote(inAmount, _base, _quote);
    }

    /// @notice Walk multiplier updates from latest to earliest and revert if any
    /// update with a significant change falls within the pause window.
    function _checkMultiplierUpdates() internal view {
        uint256 length = IBackedAutoFeeToken(xStocksToken).multiplierUpdatesLength();
        if (length == 0) return;

        uint256 index = length;
        while (index > 0) {
            --index;
            (uint256 previousMultiplier, uint256 newMultiplier, uint256 activationTime) =
                IBackedAutoFeeToken(xStocksToken).multiplierUpdates(index);

            if (activationTime > block.timestamp) {
                // Future update: check if within the before-bracket.
                if (block.timestamp + pauseTimeBefore >= activationTime) {
                    _checkMultiplierChange(previousMultiplier, newMultiplier);
                }
                // Continue to previous updates.
            } else {
                // Past/current update: check if within the after-bracket.
                if (activationTime + pauseTimeAfter >= block.timestamp) {
                    _checkMultiplierChange(previousMultiplier, newMultiplier);
                } else {
                    // the update is beyond the after-bracket
                    break;
                }
                // Continue to previous updates.
            }
        }
    }

    /// @notice Revert if the relative multiplier change is >= maxAllowedMultiplierChange.
    function _checkMultiplierChange(uint256 previousMultiplier, uint256 newMultiplier) internal view {
        uint256 diff =
            newMultiplier > previousMultiplier ? newMultiplier - previousMultiplier : previousMultiplier - newMultiplier;
        if (diff * 1e18 / previousMultiplier >= maxAllowedMultiplierChange) {
            revert PriceOracle_MultiplierUpdatePause();
        }
    }
}
