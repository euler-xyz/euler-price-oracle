// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Ownable} from "@solady/auth/Ownable.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {UniswapV3ConfigLib} from "src/adapter/uniswap/UniswapV3Config.sol";
import {UniswapV3Oracle} from "src/adapter/uniswap/UniswapV3Oracle.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract GovernedUniswapV3Oracle is Ownable, UniswapV3Oracle {
    error PoolMismatch(address configPool, address factoryPool);

    constructor(address _uniswapV3Factory, address _owner) UniswapV3Oracle(_uniswapV3Factory) {
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
        configs[token0][token1] = UniswapV3ConfigLib.empty();
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.GovernedUniswapV3Oracle(owner());
    }
}
