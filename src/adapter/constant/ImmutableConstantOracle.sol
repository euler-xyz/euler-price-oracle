// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseOracle} from "src/BaseOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract ImmutableConstantOracle is BaseOracle {
    uint256 public constant PRECISION = 10 ** 27;
    address public immutable base;
    address public immutable quote;
    uint256 public immutable rate;

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

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.ConstantOracle();
    }

    function _initializeOracle(bytes memory) internal override {}

    function _getQuote(uint256 _inAmount, address _base, address _quote) private view returns (uint256) {
        if (_base != base || _quote != quote) revert Errors.EOracle_NotSupported(_base, _quote);
        return _inAmount * rate / PRECISION;
    }
}
