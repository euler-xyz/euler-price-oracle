// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IUniswapV3Factory} from "@uniswap-v3-core/interfaces/IUniswapV3Factory.sol";
import {IUniswapV3Pool} from "@uniswap-v3-core/interfaces/IUniswapV3Pool.sol";
import {PoolAddress} from "@uniswap-v3-periphery/libraries/PoolAddress.sol";

contract ImmutableUniswapV3Adapter {
    IUniswapV3Factory public immutable uniswapV3Factory;

    uint24[] public feeTiers = [10, 500, 3000, 10000];

    constructor(address _uniswapV3Factory) {
        uniswapV3Factory = IUniswapV3Factory(_uniswapV3Factory);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        PoolAddress.PoolKey memory key = PoolAddress.getPoolKey(base, quote, 3000);
        address pool = PoolAddress.computeAddress(address(uniswapV3Factory), key);
        // (twap, twapPeriod) = callUniswapObserve(asset, assetDecimalsScaler, pool, config.twapWindow);
    }

    function addFeeTier(uint24 fee) external {
        int24 tickSpacing = uniswapV3Factory.feeAmountTickSpacing(fee);
    }
}
