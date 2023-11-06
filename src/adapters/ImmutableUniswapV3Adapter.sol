// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {PoolAddress} from "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";

contract ImmutableUniswapV3Adapter {
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

        int24 chosenTick;
        uint128 bestLiquidity;
        for (uint256 i = 0; i < 4;) {
            uint24 fee = fees[i];
            address pool = _computePoolAddress(base, quote, fee);
            (int24 arithmeticMeanTick, uint128 harmonicMeanLiquidity) = OracleLibrary.consult(pool, twapWindow);
            if (harmonicMeanLiquidity > bestLiquidity) chosenTick = arithmeticMeanTick;

            unchecked {
                ++i;
            }
        }

        uint256 amountOut = OracleLibrary.getQuoteAtTick(chosenTick, uint128(inAmount), base, quote);
        return amountOut;
    }

    function _computePoolAddress(address base, address quote, uint24 fee) private view returns (address) {
        PoolAddress.PoolKey memory key = PoolAddress.getPoolKey(base, quote, fee);
        return PoolAddress.computeAddress(address(uniswapV3Factory), key);
    }
}
