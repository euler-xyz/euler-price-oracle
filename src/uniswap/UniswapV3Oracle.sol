// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {IOracle} from "src/interfaces/IOracle.sol";

abstract contract UniswapV3Oracle is IOracle {
    IUniswapV3Factory public immutable uniswapV3Factory;
    mapping(address token0 => mapping(address token1 => UniswapV3Config)) public configs;
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    event ConfigSet(address indexed token0, address indexed token1, address indexed pool, uint24 twapWindow);

    struct UniswapV3Config {
        address pool;
        uint32 validUntil;
        uint24 twapWindow;
        uint24 fee;
        uint8 token0Decimals;
        uint8 token1Decimals;
    }

    error ConfigExpired(address base, address quote);
    error InAmountTooLarge();
    error NoPoolConfigured(address base, address quote);

    constructor(address _uniswapV3Factory) {
        uniswapV3Factory = IUniswapV3Factory(_uniswapV3Factory);
    }

    function canQuote(uint256 inAmount, address base, address quote) external view returns (bool) {
        if (inAmount > type(uint128).max) return false;
        UniswapV3Config memory config = _getConfig(base, quote);
        if (config.pool == address(0)) return false;
        if (config.validUntil < block.timestamp) return false;
        return true;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        if (inAmount > type(uint128).max) revert InAmountTooLarge();
        UniswapV3Config memory config = _getOrRevertConfig(base, quote);

        (int24 meanTick,) = OracleLibrary.consult(config.pool, config.twapWindow);
        return OracleLibrary.getQuoteAtTick(meanTick, uint128(inAmount), base, quote);
    }

    function _getConfig(address base, address quote) internal view returns (UniswapV3Config memory) {
        return configs[base][quote];
    }

    function _getOrRevertConfig(address base, address quote) internal view returns (UniswapV3Config memory) {
        UniswapV3Config memory config = _getConfig(base, quote);
        if (config.pool == address(0)) revert NoPoolConfigured(base, quote);
        if (config.validUntil < block.timestamp) revert ConfigExpired(base, quote);
        return config;
    }

    function _setConfig(address token0, address token1, address pool, uint32 validUntil, uint24 fee, uint24 twapWindow)
        internal
        returns (UniswapV3Config memory)
    {
        uint8 token0Decimals = ERC20(token0).decimals();
        uint8 token1Decimals = ERC20(token1).decimals();

        UniswapV3Config memory config = UniswapV3Config({
            pool: pool,
            validUntil: validUntil,
            twapWindow: twapWindow,
            fee: fee,
            token0Decimals: token0Decimals,
            token1Decimals: token1Decimals
        });
        configs[token0][token1] = config;

        emit ConfigSet(token0, token1, pool, twapWindow);

        return config;
    }

    function _computePoolAddress(address base, address quote, uint24 fee) internal view returns (address pool) {
        (address token0, address token1) = _sortTokens(base, quote);
        bytes32 create2Address = keccak256(
            abi.encodePacked(
                hex"ff", address(uniswapV3Factory), keccak256(abi.encode(token0, token1, fee)), POOL_INIT_CODE_HASH
            )
        );
        assembly {
            pool := create2Address
        }
    }

    function _sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return (tokenA < tokenB) ? (tokenA, tokenB) : (tokenB, tokenA);
    }
}
