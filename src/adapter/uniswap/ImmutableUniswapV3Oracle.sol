// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {OracleLibrary} from "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
import {UniswapV3Config} from "src/adapter/uniswap/UniswapV3Config.sol";
import {UniswapV3Oracle} from "src/adapter/uniswap/UniswapV3Oracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract ImmutableUniswapV3Oracle is UniswapV3Oracle {
    uint24 public constant DEFAULT_TWAP_WINDOW = 30 minutes;

    constructor(address _uniswapV3Factory) UniswapV3Oracle(_uniswapV3Factory) {}

    function updateConfig(address base, address quote) external returns (UniswapV3Config) {
        (address token0, address token1) = _sortTokens(base, quote);

        uint24[4] memory fees = [uint24(100), 500, 3000, 10000];
        uint24 selectedFee;
        address selectedPool;
        uint32 selectedTwapWindow;
        uint128 bestLiquidity;
        for (uint256 i = 0; i < 4; ++i) {
            uint24 fee = fees[i];
            address pool = _computePoolAddress(base, quote, fee);
            if (pool.code.length == 0) continue;

            uint32 maxTwapWindow = OracleLibrary.getOldestObservationSecondsAgo(pool);
            uint32 twapWindow = maxTwapWindow < DEFAULT_TWAP_WINDOW ? maxTwapWindow : DEFAULT_TWAP_WINDOW;
            (, uint128 meanLiquidity) = OracleLibrary.consult(pool, twapWindow);
            if (meanLiquidity >= bestLiquidity) {
                bestLiquidity = meanLiquidity;
                selectedFee = fee;
                selectedPool = pool;
                selectedTwapWindow = twapWindow;
            }
        }

        if (selectedPool == address(0)) revert Errors.UniswapV3_RoundTooLong(base, quote);

        uint32 validUntil = uint32(block.timestamp) + selectedTwapWindow / 4; // todo: this can be a bit more accurate

        return _setConfig(token0, token1, selectedPool, validUntil, selectedFee, uint24(selectedTwapWindow));
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.ImmutableUniswapV3Oracle();
    }
}
