// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {BaseAdapter, Errors, IPriceOracle} from "../BaseAdapter.sol";
import {IOracle} from "./IOracle.sol";

/// @title RigoblockOracle
/// @custom:security-contact security@rigoblock.com
/// @author Rigoblock (https://rigoblock.com/)
/// @notice Adapter for Rigoblock's Uniswap V4 TWAP oracle hook.
/// @dev This oracle supports quoting tokenA/tokenB and tokenB/tokenA of the given pool.
/// WARNING: READ THIS BEFORE DEPLOYING
/// The cardinality of the observation buffer must be grown sufficiently to accommodate for the chosen TWAP window.
/// The observation buffer must contain enough observations to accommodate for the chosen TWAP window.
/// The chosen pool must have enough total liquidity to resist manipulation.
/// The chosen pool must have had sufficient liquidity when past observations were recorded in the buffer.
contract RigoblockOracle is BaseAdapter {
    /// @dev The minimum length of the TWAP window.
    uint32 internal constant MIN_TWAP_WINDOW = 5 minutes;
    /// @inheritdoc IPriceOracle
    string public constant name = "RigoblockOracle";
    /// @notice One of the tokens in the pool.
    address public immutable tokenA;
    /// @notice The other token in the pool.
    address public immutable tokenB;
    /// @notice The desired length of the twap window.
    uint32 public immutable twapWindow;
    /// @notice The address of the BackGeoOracle hook.
    address public immutable backGeoOracle;

    /// @notice Deploy a UniswapV3Oracle.
    /// @dev The oracle will support tokenA/tokenB and tokenB/tokenA pricing.
    /// @param _tokenA One of the tokens in the pool.
    /// @param _tokenB The other token in the pool.
    /// @param _twapWindow The desired length of the twap window.
    /// @param _backGeoOracle The address of the Uniswap V4 BackGeoOracle oracle hook.
    constructor(address _tokenA, address _tokenB, uint32 _twapWindow, address _backGeoOracle) {
        if (_twapWindow < MIN_TWAP_WINDOW || _twapWindow > uint32(type(int32).max)) {
            revert Errors.PriceOracle_InvalidConfiguration();
        }
        tokenA = _tokenA;
        tokenB = _tokenB;
        twapWindow = _twapWindow;
        backGeoOracle = _backGeoOracle;
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(tokenA),
            currency1: Currency.wrap(tokenB),
            fee: 0,
            tickSpacing: TickMath.MAX_TICK_SPACING,
            hooks: IHooks(backGeoOracle)
        });
        IOracle.ObservationState memory state = IOracle(backGeoOracle).getState(key);
        if (state.cardinality == 0) revert Errors.PriceOracle_InvalidConfiguration();
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
        secondsAgos[0] = twapWindow;

        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(tokenA),
            currency1: Currency.wrap(tokenB),
            fee: 0,
            tickSpacing: TickMath.MAX_TICK_SPACING,
            hooks: IHooks(backGeoOracle)
        });

        // Calculate the mean tick over the twap window.
        (int48[] memory tickCumulatives,) = IOracle(backGeoOracle).observe(key, secondsAgos);
        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 tick = int24(tickCumulativesDelta / int56(uint56(twapWindow)));
        if (tickCumulativesDelta < 0 && (tickCumulativesDelta % int56(uint56(twapWindow)) != 0)) tick--;
        return OracleLibrary.getQuoteAtTick(tick, uint128(inAmount), base, quote);
    }
}
