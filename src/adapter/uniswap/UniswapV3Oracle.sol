// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC20} from "@solady/tokens/ERC20.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {UniswapV3Config, UniswapV3ConfigLib} from "src/adapter/uniswap/UniswapV3Config.sol";
import {Errors} from "src/lib/Errors.sol";

abstract contract UniswapV3Oracle is BaseOracle {
    struct ConfigParams {
        address token0;
        address token1;
        address pool;
        uint32 validUntil;
        uint24 fee;
        uint24 twapWindow;
    }

    IUniswapV3Factory public immutable uniswapV3Factory;
    mapping(address token0 => mapping(address token1 => UniswapV3Config)) public configs;
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    event ConfigSet(address indexed token0, address indexed token1, address indexed pool, uint24 twapWindow);

    constructor(address _uniswapV3Factory, ConfigParams[] memory _initialConfigs) {
        uniswapV3Factory = IUniswapV3Factory(_uniswapV3Factory);
        uint256 length = _initialConfigs.length;
        for (uint256 i = 0; i < length;) {
            _setConfig(_initialConfigs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function _setConfig(ConfigParams memory params) internal returns (UniswapV3Config) {
        uint8 token0Decimals = ERC20(params.token0).decimals();
        uint8 token1Decimals = ERC20(params.token1).decimals();

        UniswapV3Config config = UniswapV3ConfigLib.from(
            params.pool, params.validUntil, params.twapWindow, params.fee, token0Decimals, token1Decimals
        );
        configs[params.token0][params.token1] = config;

        emit ConfigSet(params.token0, params.token1, params.pool, params.twapWindow);
        return config;
    }

    function _getConfig(address base, address quote) internal view returns (UniswapV3Config) {
        (address token0, address token1) = _sortTokens(base, quote);
        return configs[token0][token1];
    }

    function _getConfigOrRevert(address base, address quote) internal view returns (UniswapV3Config) {
        UniswapV3Config config = _getConfig(base, quote);
        if (config.isEmpty()) revert Errors.EOracle_NotSupported(base, quote);
        if (config.getValidUntil() < block.timestamp) revert Errors.ConfigExpired(base, quote);
        return config;
    }

    function _computePoolAddress(address base, address quote, uint24 fee) internal view returns (address pool) {
        (address token0, address token1) = _sortTokens(base, quote);
        bytes32 poolKey = keccak256(abi.encode(token0, token1, fee));
        bytes32 create2Address =
            keccak256(abi.encodePacked(hex"ff", address(uniswapV3Factory), poolKey, POOL_INIT_CODE_HASH));

        return address(uint160(uint256(create2Address)));
    }

    function _sortTokens(address tokenA, address tokenB) internal pure returns (address, address) {
        return (tokenA < tokenB) ? (tokenA, tokenB) : (tokenB, tokenA);
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        if (inAmount > type(uint128).max) revert Errors.EOracle_Overflow();
        UniswapV3Config config = _getConfigOrRevert(base, quote);

        (int24 meanTick,) = OracleLibrary.consult(config.getPool(), config.getTwapWindow());
        return OracleLibrary.getQuoteAtTick(meanTick, uint128(inAmount), base, quote);
    }
}
