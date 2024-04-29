// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

contract StubPriceOracle {
    mapping(address => mapping(address => uint256)) prices;
    bool doRevert;

    function setRevert(bool _doRevert) external {
        doRevert = _doRevert;
    }

    function setPrice(address base, address quote, uint256 price) external {
        prices[base][quote] = price;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        if (doRevert) revert("oops");
        return _calcQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        if (doRevert) revert("oops");
        return (_calcQuote(inAmount, base, quote), _calcQuote(inAmount, base, quote));
    }

    function _calcQuote(uint256 inAmount, address base, address quote) internal view returns (uint256) {
        if (prices[base][quote] != 0) return inAmount * prices[base][quote] / 1e18;
        if (prices[quote][base] != 0) return inAmount * 1e18 / prices[quote][base];
        revert("Price not set.");
    }
}
