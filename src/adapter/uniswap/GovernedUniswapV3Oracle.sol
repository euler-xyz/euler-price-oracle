// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {UniswapV3ConfigLib} from "src/adapter/uniswap/UniswapV3Config.sol";
import {UniswapV3Oracle} from "src/adapter/uniswap/UniswapV3Oracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract GovernedUniswapV3Oracle is UniswapV3Oracle {
    constructor(address _uniswapV3Factory, address _owner) UniswapV3Oracle(_uniswapV3Factory) {}

    function addConfig(address pool, uint24 twapWindow) public onlyGovernor {
        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();
        uint24 fee = IUniswapV3Pool(pool).fee();
        address factoryPool = uniswapV3Factory.getPool(token0, token1, fee);
        if (factoryPool != pool) revert Errors.UniswapV3_PoolMismatch(pool, factoryPool);

        _setConfig(
            UniswapV3Oracle.ConfigParams({
                token0: token0,
                token1: token1,
                pool: pool,
                validUntil: type(uint32).max,
                fee: fee,
                twapWindow: uint24(twapWindow)
            })
        );
    }

    function removeConfig(address pool) public onlyGovernor {
        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();
        configs[token0][token1] = UniswapV3ConfigLib.empty();
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.GovernedUniswapV3Oracle(governor);
    }
}
