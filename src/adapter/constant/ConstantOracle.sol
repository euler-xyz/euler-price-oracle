// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

contract ConstantOracle {
    uint256 public constant PRECISION_DECIMALS = 27;
    address public immutable base;
    address public immutable quote;
    uint256 public immutable rate;

    error NotSupported(address base, address quote);

    constructor(address _base, address _quote, uint256 _rate) {
        base = _base;
        quote = _quote;
        rate = _rate;
    }

    function canQuote(uint256, address _base, address _quote) external view returns (bool) {
        return base == _base && quote == _quote;
    }

    function getQuote(uint256 _inAmount, address _base, address _quote) external view returns (uint256) {
        if (_base != base || _quote != quote) revert NotSupported(_base, _quote);
        uint256 price = _inAmount * rate / 10 ** PRECISION_DECIMALS;
        return price;
    }

    function getQuotes(uint256 _inAmount, address _base, address _quote) external view returns (uint256, uint256) {
        if (_base != base || _quote != quote) revert NotSupported(_base, _quote);
        uint256 price = _inAmount * rate / 10 ** PRECISION_DECIMALS;
        return (price, price);
    }
}
