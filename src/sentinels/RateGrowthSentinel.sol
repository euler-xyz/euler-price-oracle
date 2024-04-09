// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {BaseAdapter} from "src/adapter/BaseAdapter.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {ScaleUtils} from "src/lib/ScaleUtils.sol";

contract RateGrowthSentinel is BaseAdapter {
    address public immutable wrappedAdapter;
    address public immutable base;
    address public immutable quote;
    uint256 public immutable maxGrowthPerSecond;
    uint256 public immutable snapshotRate;
    uint256 public immutable snapshotAt;
    uint8 internal immutable baseDecimals;
    uint8 internal immutable quoteDecimals;

    constructor(address _wrappedAdapter, address _base, address _quote, uint256 _maxGrowthPerSecond) {
        wrappedAdapter = _wrappedAdapter;
        base = _base;
        quote = _quote;
        maxGrowthPerSecond = _maxGrowthPerSecond;

        baseDecimals = _getDecimals(base);
        quoteDecimals = _getDecimals(quote);

        snapshotRate = IPriceOracle(wrappedAdapter).getQuote(10 ** baseDecimals, base, quote);
        snapshotAt = block.timestamp;
    }

    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);
        uint256 outAmount = IPriceOracle(wrappedAdapter).getQuote(inAmount, _base, _quote);

        uint256 maxRate = snapshotRate + maxGrowthPerSecond * (block.timestamp - snapshotAt);
        uint256 maxOutAmount;
        if (inverse) {
            maxOutAmount = inAmount * 10 ** quoteDecimals / maxRate;
        } else {
            maxOutAmount = inAmount * maxRate / 10 ** baseDecimals;
        }
        return outAmount < maxOutAmount ? outAmount : maxOutAmount;
    }
}
