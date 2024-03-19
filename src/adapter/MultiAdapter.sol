// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {BaseAdapter} from "src/adapter/BaseAdapter.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {ScaleUtils, Scale} from "src/lib/ScaleUtils.sol";

contract MultiAdapter is BaseAdapter {
    address public immutable base;
    address public immutable through;
    address public immutable quote;
    address public immutable oracleA;
    address public immutable oracleB;

    constructor(address _base, address _through, address _quote, address _oracleA, address _oracleB) {
        base = _base;
        through = _through;
        quote = _quote;
        oracleA = _oracleA;
        oracleB = _oracleB;
    }

    function _getQuote(uint256 inAmount, address _base, address _quote) internal view override returns (uint256) {
        bool inverse = ScaleUtils.getDirectionOrRevert(_base, base, _quote, quote);

        if (inverse) {
            // quote/through * through/base
            inAmount = IPriceOracle(oracleB).getQuote(inAmount, quote, through);
            return IPriceOracle(oracleA).getQuote(inAmount, through, base);
        } else {
            // base/through * through/quote
            inAmount = IPriceOracle(oracleA).getQuote(inAmount, base, through);
            return IPriceOracle(oracleB).getQuote(inAmount, through, quote);
        }
    }
}
