// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {FixedPointMathLib} from "@solady/utils/FixedPointMathLib.sol";
import {BaseAdapter, IPriceOracle} from "src/adapter/BaseAdapter.sol";
import {ScaleUtils} from "src/lib/ScaleUtils.sol";

contract RateGrowthSentinel is BaseAdapter {
    /// @inheritdoc IPriceOracle
    string public constant name = "RateGrowthSentinel";
    address public immutable wrappedAdapter;
    address public immutable base;
    address public immutable quote;
    uint256 public immutable maxGrowthPerSecond;
    uint256 public immutable snapshotRate;
    uint256 public immutable snapshotAt;
    uint256 internal immutable baseScalar;
    uint256 internal immutable quoteScalar;

    constructor(address _wrappedAdapter, address _base, address _quote, uint256 _maxGrowthPerSecond) {
        wrappedAdapter = _wrappedAdapter;
        base = _base;
        quote = _quote;
        maxGrowthPerSecond = _maxGrowthPerSecond;

        baseScalar = 10 ** _getDecimals(base);
        quoteScalar = 10 ** _getDecimals(quote);

        snapshotRate = IPriceOracle(wrappedAdapter).getQuote(baseScalar, base, quote);
        snapshotAt = block.timestamp;
    }

    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);
        uint256 outAmount = IPriceOracle(wrappedAdapter).getQuote(inAmount, _base, _quote);

        uint256 maxRate = snapshotRate + maxGrowthPerSecond * (block.timestamp - snapshotAt);
        uint256 maxOutAmount;
        if (inverse) {
            maxOutAmount = FixedPointMathLib.fullMulDiv(inAmount, quoteScalar, maxRate);
        } else {
            maxOutAmount = FixedPointMathLib.fullMulDiv(inAmount, maxRate, baseScalar);
        }
        return outAmount < maxOutAmount ? outAmount : maxOutAmount;
    }
}
