// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable} from "@solady/auth/Ownable.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";

import {IAdapter} from "src/uniswap/UniswapV3Adapter.sol";

contract GovernedUniswapV3Adapter is Ownable, UniswapV3Adapter {
    error PoolMismatch(address configPool, address factoryPool);
    error NoConfig(address base, address quote);

    constructor(address _uniswapV3Factory, address _owner) UniswapV3Adapter(_uniswapV3Factory) {
        _initializeOwner(_owner);
    }

    function addConfig(address pool, uint24 twapWindow) public onlyOwner {
        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();
        uint24 fee = IUniswapV3Pool(pool).fee();
        address factoryPool = uniswapV3Factory.getPool(token0, token1, fee);
        if (factoryPool != pool) revert PoolMismatch(pool, factoryPool);

        _setConfig(token0, token1, pool, type(uint32).max, fee, twapWindow);
    }

    function removeConfig(address pool) public onlyOwner {
        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();
        delete configs[token0][token1];
    }
}
