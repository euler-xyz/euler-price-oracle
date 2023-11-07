// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import {UniswapV3Adapter} from "src/uniswap/UniswapV3Adapter.sol";

contract ImmutableUniswapV3Adapter is UniswapV3Adapter {
    uint24 public constant DEFAULT_TWAP_WINDOW = 30 minutes;

    constructor(address _uniswapV3Factory) UniswapV3Adapter(_uniswapV3Factory) {}

    function updateConfig(address base, address quote) external returns (UniswapV3Config memory) {
        (address token0, address token1) = _sortTokens(base, quote);

        uint24[4] memory fees = [uint24(10), 500, 3000, 10000];
        uint24 selectedFee;
        address selectedPool;
        uint128 bestLiquidity;
        for (uint256 i = 0; i < 4;) {
            uint24 fee = fees[i];
            address pool = _computePoolAddress(base, quote, fee);
            (, uint128 meanLiquidity) = OracleLibrary.consult(pool, DEFAULT_TWAP_WINDOW);
            if (meanLiquidity >= bestLiquidity) {
                selectedFee = fee;
                selectedPool = pool;
                bestLiquidity = meanLiquidity;
            }

            unchecked {
                ++i;
            }
        }

        uint32 validUntil = uint32(block.timestamp) + DEFAULT_TWAP_WINDOW / 4;
        return _setConfig(token0, token1, selectedPool, validUntil, selectedFee, DEFAULT_TWAP_WINDOW);
    }
}
