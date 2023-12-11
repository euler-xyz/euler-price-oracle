// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {console2} from "forge-std/console2.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract ConstantOracle2 is BaseOracle {
    uint256 public constant PRECISION = 10 ** 27;
    uint256 public constant rate = 10 ** 27;
    uint256 public immutable immutableValue;
    uint256 public metadataValue;

    constructor(uint256 _immutableValue) {
        immutableValue = _immutableValue;
    }

    function hey() external pure virtual returns (uint256) {
        return 1;
    }

    function getQuote(uint256 _inAmount, address _base, address _quote) external view returns (uint256) {
        return _getQuote(_inAmount, _base, _quote);
    }

    function getQuotes(uint256 _inAmount, address _base, address _quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(_inAmount, _base, _quote);
        return (outAmount, outAmount);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.WstEthOracle();
    }

    function UNPACK() internal pure returns (address base, address quote) {
        assembly {
            base := shr(96, calldataload(sub(calldatasize(), 84)))
            quote := shr(96, calldataload(sub(calldatasize(), 52)))
        }
    }

    function _getQuote(uint256 _inAmount, address _base, address _quote) private view returns (uint256) {
        (address base, address quote) = UNPACK();
        if (_base != base || _quote != quote) revert Errors.EOracle_NotSupported(_base, _quote);
        return _inAmount * rate / PRECISION;
    }
}

contract ConstantOracle2Upgraded is ConstantOracle2 {
    constructor(uint256 _immutableValue) ConstantOracle2(_immutableValue) {}

    function hey() external pure override returns (uint256) {
        return 2;
    }
}
