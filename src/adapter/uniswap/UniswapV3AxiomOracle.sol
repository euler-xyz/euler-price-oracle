// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.23;

import {AxiomV2Client} from "@axiom-crypto/v2-periphery/client/AxiomV2Client.sol";

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {BaseAdapter, Errors, IPriceOracle} from "src/adapter/BaseAdapter.sol";

/// @title UniswapV3AxiomOracle
/// @custom:security-contact security@euler.xyz
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Experimental Uniswap V3 Median oracle using Axiom ZK Coprocessor.
/// @dev This oracle supports quoting tokenA/tokenB and tokenB/tokenA of the given pool.
contract UniswapV3Oracle is AxiomV2Client, BaseAdapter {
    struct Cache {
        int24 medianTick;
        uint48 updatedAt;
    }

    /// @dev The minimum length of the TWAP window.
    uint32 internal constant MIN_TWAP_WINDOW = 5 minutes;
    /// @dev Enforces that Axiom queries are fulfilled on Ethereum.
    uint64 internal constant SOURCE_CHAIN_ID = 1;
    /// @inheritdoc IPriceOracle
    string public constant name = "UniswapV3Oracle";
    bytes32 internal immutable querySchema;
    /// @notice One of the tokens in the pool.
    address public immutable tokenA;
    /// @notice The other token in the pool.
    address public immutable tokenB;
    /// @notice The fee tier of the pool.
    uint24 public immutable fee;
    /// @notice The number of blocks to look back.
    uint32 public immutable blockWindow;
    /// @notice The number of observations in the block window
    uint256 public immutable numObservations;
    /// @notice The address of the Uniswap V3 pool.
    address public immutable pool;

    /// @notice Cached median tick.
    Cache public cache;

    error InvalidAxiomCall();
    error InvalidAxiomCallback();

    /// @notice Deploy a UniswapV3Oracle.
    /// @dev The oracle will support tokenA/tokenB and tokenB/tokenA pricing.
    /// @param _tokenA One of the tokens in the pool.
    /// @param _tokenB The other token in the pool.
    /// @param _fee The fee tier of the pool.
    /// @param _blockWindow The desired length of the twap window.
    /// @param _uniswapV3Factory The address of the Uniswap V3 Factory.
    constructor(
        address _tokenA,
        address _tokenB,
        uint24 _fee,
        uint32 _blockWindow,
        address _uniswapV3Factory,
        address _axiomV2QueryAddress,
        bytes32 _querySchema
    ) AxiomV2Client(_axiomV2QueryAddress) {
        if (_blockWindow < MIN_TWAP_WINDOW || _blockWindow > uint32(type(int32).max)) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }
        querySchema = _querySchema;
        tokenA = _tokenA;
        tokenB = _tokenB;
        fee = _fee;
        blockWindow = _blockWindow;
        pool = IUniswapV3Factory(_uniswapV3Factory).getPool(tokenA, tokenB, _fee);
        if (pool == address(0)) revert Errors.PriceOracle_InvalidConfiguration();
    }

    function _axiomV2Callback(
        uint64 sourceChainId,
        address, // caller,
        bytes32 _querySchema,
        uint256, // queryId,
        bytes32[] calldata axiomResults,
        bytes calldata // extraData
    ) internal override {
        if (sourceChainId != SOURCE_CHAIN_ID) revert InvalidAxiomCallback();
        if (_querySchema != querySchema) revert InvalidAxiomCallback();
        if (axiomResults.length != 1) revert InvalidAxiomCallback();

        uint160 medianSqrtPriceX96 = uint160(uint256(axiomResults[0]));
        int24 medianTick = TickMath.getTickAtSqrtRatio(medianSqrtPriceX96);
        cache.medianTick = medianTick;
        cache.updatedAt = uint48(block.timestamp);
    }

    /// @notice Get a quote by calling the pool's TWAP oracle.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced. Either `tokenA` or `tokenB`.
    /// @param quote The token that is the unit of account. Either `tokenB` or `tokenA`.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        if (!((base == tokenA && quote == tokenB) || (base == tokenB && quote == tokenA))) {
            revert Errors.PriceOracle_NotSupported(base, quote);
        }
        // Size limitation enforced by the pool.
        if (inAmount > type(uint128).max) revert Errors.PriceOracle_Overflow();

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = blockWindow;

        // Calculate the mean tick over the twap window.
        (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 tick = int24(tickCumulativesDelta / int56(uint56(blockWindow)));
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(blockWindow)) != 0)) tick--;
        return OracleLibrary.getQuoteAtTick(tick, uint128(inAmount), base, quote);
    }

    function _validateAxiomV2Call(
        AxiomCallbackType, // callbackType,
        uint64 sourceChainId,
        address, // caller,
        bytes32 _querySchema,
        uint256, // queryId,
        bytes calldata // extraData
    ) internal view override {
        if (sourceChainId != SOURCE_CHAIN_ID) revert InvalidAxiomCall();
        if (_querySchema != querySchema) revert InvalidAxiomCall();
    }
}
