// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IOracle} from "src/interfaces/IOracle.sol";

contract ConstantOracle is IOracle {
    uint256 public constant PRECISION = 10 ** 27;
    address public immutable base;
    address public immutable quote;
    uint256 public immutable rate;

    error NotSupported(address base, address quote);

    constructor(address _base, address _quote, uint256 _rate) {
        base = _base;
        quote = _quote;
        rate = _rate;
    }

    function getQuote(uint256 _inAmount, address _base, address _quote) external view returns (uint256) {
        return _getQuote(_inAmount, _base, _quote);
    }

    function getQuotes(uint256 _inAmount, address _base, address _quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(_inAmount, _base, _quote);
        return (outAmount, outAmount);
    }

    function _getQuote(uint256 _inAmount, address _base, address _quote) private view returns (uint256) {
        if (_base != base || _quote != quote) revert NotSupported(_base, _quote);
        return _inAmount * rate / PRECISION;
    }
}
