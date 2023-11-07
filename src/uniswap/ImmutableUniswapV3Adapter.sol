// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import {UniswapV3Adapter} from "src/uniswap/UniswapV3Adapter.sol";

contract ImmutableUniswapV3Adapter is UniswapV3Adapter {
    IUniswapV3Factory public immutable uniswapV3Factory;
    uint32 public immutable twapWindow;

    error InAmountTooLarge();

    constructor(address _uniswapV3Factory, uint32 _twapWindow) {
        uniswapV3Factory = IUniswapV3Factory(_uniswapV3Factory);
        twapWindow = _twapWindow;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        if (inAmount > type(uint128).max) revert InAmountTooLarge();

        uint24[4] memory fees = [uint24(10), 500, 3000, 10000];
        int24 quoteTick;
        uint128 bestLiquidity;
        for (uint256 i = 0; i < 4;) {
            (int24 meanTick, uint128 meanLiquidity) = _consultOracle(base, quote, fees[i]);
            if (meanLiquidity > bestLiquidity) quoteTick = meanTick;

            unchecked {
                ++i;
            }
        }
        return OracleLibrary.getQuoteAtTick(quoteTick, uint128(inAmount), base, quote);
    }
}
