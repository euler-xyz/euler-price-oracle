// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable} from "@solady/auth/Ownable.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {PoolAddress} from "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";

import {IAdapter} from "src/interfaces/IAdapter.sol";

struct PoolConfig {
    address pool;
    uint24 fee;
    uint32 twapWindow;
    uint8 token0Decimals;
    uint8 token1Decimals;
}

contract ConfigurableUniswapV3Adapter is IAdapter, Ownable {
    IUniswapV3Factory public immutable uniswapV3Factory;
    mapping(address token0 => mapping(address token1 => PoolConfig)) public configs;

    error PoolMismatch(address configPool, address factoryPool);
    error NoConfig(address base, address quote);

    constructor(address _uniswapV3Factory) {
        _initializeOwner(msg.sender);
        uniswapV3Factory = IUniswapV3Factory(_uniswapV3Factory);
    }

    function setConfig(address pool, uint32 twapWindow) public {
        address token0 = IUniswapV3Pool(pool).token0();
        address token1 = IUniswapV3Pool(pool).token1();
        uint24 fee = IUniswapV3Pool(pool).fee();
        address factoryPool = uniswapV3Factory.getPool(token0, token1, fee);
        if (factoryPool != pool) revert PoolMismatch(pool, factoryPool);

        uint8 token0Decimals = ERC20(token0).decimals();
        uint8 token1Decimals = ERC20(token1).decimals();

        configs[token0][token1] = PoolConfig({
            pool: pool,
            fee: fee,
            twapWindow: twapWindow,
            token0Decimals: token0Decimals,
            token1Decimals: token1Decimals
        });
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        (address token0, address token1) = _sortTokens(base, quote);
        PoolConfig memory config = configs[token0][token1];
        if (config.pool == address(0)) revert NoConfig(base, quote);

        (int24 meanTick,) = OracleLibrary.consult(config.pool, config.twapWindow);
        return OracleLibrary.getQuoteAtTick(meanTick, uint128(inAmount), base, quote);
    }

    function _sortTokens(address tokenA, address tokenB) private pure returns (address, address) {
        return (tokenA < tokenB) ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}
