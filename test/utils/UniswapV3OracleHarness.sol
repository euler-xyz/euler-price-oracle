// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {UniswapV3Config} from "src/adapter/uniswap/UniswapV3Config.sol";
import {UniswapV3Oracle} from "src/adapter/uniswap/UniswapV3Oracle.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract UniswapV3OracleHarness is UniswapV3Oracle {
    constructor(address _uniswapV3Factory) UniswapV3Oracle(_uniswapV3Factory) {}

    function description() external view returns (OracleDescription.Description memory) {}

    function getConfig(address base, address quote) external view returns (UniswapV3Config) {
        return _getConfig(base, quote);
    }

    function getOrRevertConfig(address base, address quote) external view returns (UniswapV3Config) {
        return _getOrRevertConfig(base, quote);
    }

    function setConfig(address token0, address token1, address pool, uint32 validUntil, uint24 fee, uint24 twapWindow)
        external
        returns (UniswapV3Config)
    {
        return _setConfig(token0, token1, pool, validUntil, fee, twapWindow);
    }

    function setConfig(address token0, address token1, UniswapV3Config config) external {
        configs[token0][token1] = config;
    }

    function sortTokens(address tokenA, address tokenB) external pure returns (address, address) {
        return _sortTokens(tokenA, tokenB);
    }
}
