// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {BaseAdapter} from "src/adapter/BaseAdapter.sol";
import {Errors} from "src/lib/Errors.sol";

/// @title UniswapV3Oracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for Uniswap V3's TWAP oracle.
/// @dev This oracle supports quoting token0/token1 and token1/token0 of the given pool.
contract UniswapV3Oracle is BaseAdapter {
    /// @dev The lower bound for the duration between consecutive blocks. On Ethereum, the block time is fixed at 12 seconds.
    /// Note that the average block time may be higher than this due to missed epoch slots.
    /// This value is used to calculate the worst-case upper bound for the pool's observation cardinality.
    uint256 internal constant BLOCK_TIME = 12 seconds;
    /// @dev The minimum length of the TWAP window is 1 minute.
    uint32 internal constant MIN_TWAP_WINDOW = 60 seconds;
    /// @dev The maximum length of the TWAP window supported by the oracle. The pool stores past observations in a
    /// ring buffer data structure with maximum size 2^16. This value is approximately 9.1 days.
    uint32 internal constant MAX_TWAP_WINDOW = uint32(type(uint16).max) * uint32(BLOCK_TIME);
    /// @notice One of the tokens in the pool.
    address public immutable token0;
    /// @notice The other token in the pool.
    address public immutable token1;
    /// @notice The fee tier of the pool.
    uint24 public immutable fee;
    /// @notice The length of the
    uint32 public immutable twapWindow;
    /// @notice The address of the Uniswap V3 pool.
    address public immutable pool;

    /// @notice Deploy a UniswapV3Oracle.
    /// @param _base The address of the ERC4626 vault.
    /// @dev The oracle will support share/asset and asset/share pricing.
    constructor(address _base, address _quote, uint24 _fee, uint32 _twapWindow, address _uniswapV3Factory) {
        if (_twapWindow < MIN_TWAP_WINDOW || _twapWindow > MAX_TWAP_WINDOW) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }
        fee = _fee;
        twapWindow = _twapWindow;
        (token0, token1) = _base < _quote ? (_base, _quote) : (_quote, _base);
        pool = IUniswapV3Factory(_uniswapV3Factory).getPool(_base, _quote, _fee);

        // Make sure the TWAP oracle's observations buffer is big enough to support the TWAP window.
        (,,,, uint16 observationCardinalityNext,,) = IUniswapV3Pool(pool).slot0();
        // This is the worst-case required cardinality, assuming no missed epoch slots and the pool is updated every block.
        uint16 requiredObservationCardinality = uint16(_twapWindow / BLOCK_TIME);
        if (requiredObservationCardinality < observationCardinalityNext) {
            IUniswapV3Pool(pool).increaseObservationCardinalityNext(requiredObservationCardinality);
            // TWAP pricing may revert while the observation buffer is growing to its new cardinality.
        }
    }

    /// @notice Get a quote by calling the pool's TWAP oracle.
    /// @dev Supports spot pricing if twapWindow=0.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced. Either `token0` or `token1`.
    /// @param quote The token that is the unit of account. Either `token1` or `token0`.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address base, address quote) internal view override returns (uint256) {
        // Accept only token0/token1 and token1/token0.
        if (!((base == token0 && quote == token1) || (base == token1 && quote == token0))) {
            revert Errors.PriceOracle_NotSupported(base, quote);
        }
        // Size limitation enforced by the pool.
        if (inAmount > type(uint128).max) revert Errors.PriceOracle_Overflow();

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = twapWindow;
        secondsAgos[1] = 0;

        // Calculate the mean tick over the twap window.
        (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);
        int24 tick = int24((tickCumulatives[1] - tickCumulatives[0]) / int32(twapWindow));
        return OracleLibrary.getQuoteAtTick(tick, uint128(inAmount), base, quote);
    }
}
