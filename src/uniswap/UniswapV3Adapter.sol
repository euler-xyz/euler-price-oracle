// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {PoolAddress} from "@uniswap/v3-periphery/contracts/libraries/PoolAddress.sol";

import {IAdapter} from "src/interfaces/IAdapter.sol";

abstract contract UniswapV3Adapter is IAdapter {
    uint24 public constant DEFAULT_TWAP_WINDOW = 6 hours;
    IUniswapV3Factory public immutable uniswapV3Factory;
    mapping(address token0 => mapping(address token1 => UniswapV3Config)) public configs;

    event ConfigSet(address indexed token0, address indexed token1, address indexed pool, uint24 twapWindow);

    struct UniswapV3Config {
        address pool;
        uint32 goodUntil;
        uint24 twapWindow;
        uint24 fee;
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    error ConfigExpired(address base, address quote);
    error NoPoolConfigured(address base, address quote);

    constructor(address _uniswapV3Factory) {
        uniswapV3Factory = IUniswapV3Factory(_uniswapV3Factory);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        if (inAmount > type(uint128).max) revert InAmountTooLarge();

        UniswapV3Config memory config = _getConfig(base, quote);

        (int24 meanTick,) = OracleLibrary.consult(config.pool, config.twapWindow);
        return OracleLibrary.getQuoteAtTick(meanTick, uint128(inAmount), base, quote);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        if (inAmount > type(uint128).max) revert InAmountTooLarge();

        UniswapV3Config memory config = _getConfig(base, quote);

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

    function _getConfig(address base, address quote) internal view returns (UniswapV3Config memory) {
        UniswapV3Config memory config = configs[base][quote];
        if (config.pool == address(0)) revert NoPoolConfigured(base, quote);
        if (config.goodUntil < block.timestamp) revert ConfigExpired(base, quote);
        return config;
    }

    function _setConfig(address token0, address token1, address pool, uint32 goodUntil, uint24 fee, uint24 twapWindow)
        internal
        returns (ChainlinkConfig memory)
    {
        uint8 token0Decimals = ERC20(token0).decimals();
        uint8 token1Decimals = ERC20(token1).decimals();

        UniswapV3Config memory config = UniswapV3Config({
            pool: pool,
            goodUntil: goodUntil,
            twapWindow: twapWindow,
            fee: fee,
            token0Decimals: token0Decimals,
            token1Decimals: token1Decimals
        });
        configs[token0][token1] = config;

        emit ConfigSet(token0, token1, pool, twapWindow);

        return config;
    }

    function _consultOracle(address base, address quote, uint24 fee) private view returns (int24, uint128) {
        address pool = _computePoolAddress(base, quote, fee);
        return OracleLibrary.consult(pool, twapWindow);
    }

    function _computePoolAddress(address base, address quote, uint24 fee) private view returns (address) {
        PoolAddress.PoolKey memory key = PoolAddress.getPoolKey(base, quote, fee);
        return PoolAddress.computeAddress(address(uniswapV3Factory), key);
    }

    function _sortTokens(address tokenA, address tokenB) private pure returns (address, address) {
        return (tokenA < tokenB) ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}
