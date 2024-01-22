// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {Errors} from "src/lib/Errors.sol";

contract UniswapV3Oracle {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    address public immutable base;
    address public immutable quote;
    uint24 public immutable fee;
    address public immutable pool;
    uint32 public immutable twapWindow;
    address public immutable uniswapV3Factory;

    constructor(address _base, address _quote, uint24 _fee, uint32 _twapWindow, address _uniswapV3Factory) {
        base = _base;
        quote = _quote;
        fee = _fee;
        twapWindow = _twapWindow;
        uniswapV3Factory = _uniswapV3Factory;

        (address token0, address token1) = _base < _quote ? (_base, _quote) : (_quote, _base);
        bytes32 poolKey = keccak256(abi.encode(token0, token1, _fee));
        bytes32 create2Hash = keccak256(abi.encodePacked(hex"ff", _uniswapV3Factory, poolKey, POOL_INIT_CODE_HASH));
        pool = address(uint160(uint256(create2Hash)));
    }

    function getQuote(uint256 inAmount, address _base, address _quote) external view returns (uint256) {
        return _getQuote(inAmount, _base, _quote);
    }

    function getQuotes(uint256 inAmount, address _base, address _quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, _base, _quote);
        return (outAmount, outAmount);
    }

    function _getQuote(uint256 inAmount, address _base, address _quote) internal view returns (uint256) {
        if ((_base != base || _quote != quote) && (_quote != base || _base != quote)) {
            revert Errors.EOracle_NotSupported(_base, _quote);
        }
        if (inAmount > type(uint128).max) revert Errors.EOracle_Overflow();
        (int24 meanTick,) = OracleLibrary.consult(pool, twapWindow);
        return OracleLibrary.getQuoteAtTick(meanTick, uint128(inAmount), _base, _quote);
    }
}
