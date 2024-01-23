// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract UniswapV3Oracle is IEOracle {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;
    uint32 internal constant MAX_TWAP_WINDOW = 9 days;
    uint256 internal constant BLOCK_TIME = 12 seconds;

    address public immutable base;
    address public immutable quote;
    address public immutable pool;
    address public immutable uniswapV3Factory;
    uint24 public immutable fee;
    uint32 public immutable twapWindow;
    uint256 public immutable availableAtBlock;

    constructor(address _base, address _quote, uint24 _fee, uint32 _twapWindow, address _uniswapV3Factory) {
        if (_twapWindow > MAX_TWAP_WINDOW) revert Errors.UniswapV3_TwapWindowTooLong(_twapWindow, MAX_TWAP_WINDOW);

        base = _base;
        quote = _quote;
        fee = _fee;
        twapWindow = _twapWindow;
        uniswapV3Factory = _uniswapV3Factory;

        (address token0, address token1) = _base < _quote ? (_base, _quote) : (_quote, _base);
        bytes32 poolKey = keccak256(abi.encode(token0, token1, _fee));
        bytes32 create2Hash = keccak256(abi.encodePacked(hex"ff", _uniswapV3Factory, poolKey, POOL_INIT_CODE_HASH));
        pool = address(uint160(uint256(create2Hash)));

        (,,, uint16 observationCardinality, uint16 observationCardinalityNext,,) = IUniswapV3Pool(pool).slot0();
        uint16 requiredObservationCardinality = uint16(_twapWindow / BLOCK_TIME);
        if (requiredObservationCardinality < observationCardinalityNext) {
            IUniswapV3Pool(pool).increaseObservationCardinalityNext(requiredObservationCardinality);
        }

        if (requiredObservationCardinality < observationCardinality) {
            availableAtBlock = block.number;
        } else {
            uint16 observationsNeeded = requiredObservationCardinality - observationCardinality;
            availableAtBlock = block.number + observationsNeeded;
        }
    }

    function getQuote(uint256 inAmount, address _base, address _quote) external view returns (uint256) {
        return _getQuote(inAmount, _base, _quote);
    }

    function getQuotes(uint256 inAmount, address _base, address _quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, _base, _quote);
        return (outAmount, outAmount);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.UniswapV3Oracle();
    }

    function _getQuote(uint256 inAmount, address _base, address _quote) internal view returns (uint256) {
        if ((_base != base || _quote != quote) && (_quote != base || _base != quote)) {
            revert Errors.EOracle_NotSupported(_base, _quote);
        }
        if (inAmount > type(uint128).max) revert Errors.EOracle_Overflow();
        if (block.number < availableAtBlock) revert Errors.UniswapV3_ObservationsNotInitialized(availableAtBlock);

        int24 tick;
        if (twapWindow == 0) {
            // return the spot price
            (, tick,,,,,) = IUniswapV3Pool(pool).slot0();
        } else {
            uint32[] memory secondsAgos = new uint32[](2);
            secondsAgos[0] = twapWindow;
            secondsAgos[1] = 0;

            (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);
            tick = int24((tickCumulatives[1] - tickCumulatives[0]) / int32(twapWindow));
        }
        return OracleLibrary.getQuoteAtTick(tick, uint128(inAmount), _base, _quote);
    }
}
