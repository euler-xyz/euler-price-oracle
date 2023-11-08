// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {console2} from "forge-std/console2.sol";

type UniswapV3Config is uint256;

using UniswapV3ConfigLib for UniswapV3Config global;

library UniswapV3ConfigLib {
    uint256 internal constant POOL_MASK = 0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant VALID_UNTIL_MASK = 0x0000000000000000FFFFFFFF0000000000000000000000000000000000000000;
    uint256 internal constant TWAP_WINDOW_MASK = 0x0000000000FFFFFF000000000000000000000000000000000000000000000000;
    uint256 internal constant FEE_MASK = 0x0000FFFFFF000000000000000000000000000000000000000000000000000000;
    uint256 internal constant TOKEN0_DECIMALS_MASK = 0x00FF000000000000000000000000000000000000000000000000000000000000;
    uint256 internal constant TOKEN1_DECIMALS_MASK = 0xFF00000000000000000000000000000000000000000000000000000000000000;

    uint256 internal constant POOL_OFFSET = 0;
    uint256 internal constant VALID_UNTIL_OFFSET = 160;
    uint256 internal constant TWAP_WINDOW_OFFSET = 192;
    uint256 internal constant FEE_OFFSET = 216;
    uint256 internal constant TOKEN0_DECIMALS_OFFSET = 240;
    uint256 internal constant TOKEN1_DECIMALS_OFFSET = 248;

    function from(
        address pool,
        uint32 validUntil,
        uint24 twapWindow,
        uint24 fee,
        uint8 token0Decimals,
        uint8 token1Decimals
    ) internal pure returns (UniswapV3Config) {
        UniswapV3Config c;
        assembly {
            c := shl(TOKEN1_DECIMALS_OFFSET, token1Decimals)
            c := or(c, shl(TOKEN0_DECIMALS_OFFSET, token0Decimals))
            c := or(c, shl(FEE_OFFSET, fee))
            c := or(c, shl(TWAP_WINDOW_OFFSET, twapWindow))
            c := or(c, shl(VALID_UNTIL_OFFSET, validUntil))
            c := or(c, and(POOL_MASK, pool))
        }
        return c;
    }

    function empty() internal pure returns (UniswapV3Config) {
        return UniswapV3Config.wrap(0);
    }

    function isEmpty(UniswapV3Config config) internal pure returns (bool) {
        return UniswapV3Config.unwrap(config) == 0;
    }

    function getPool(UniswapV3Config config) internal pure returns (address) {
        return address(uint160(UniswapV3Config.unwrap(config)));
    }

    function getValidUntil(UniswapV3Config config) internal pure returns (uint32) {
        return uint32((UniswapV3Config.unwrap(config) & VALID_UNTIL_MASK) >> VALID_UNTIL_OFFSET);
    }

    function getTwapWindow(UniswapV3Config config) internal pure returns (uint24) {
        return uint24((UniswapV3Config.unwrap(config) & TWAP_WINDOW_MASK) >> TWAP_WINDOW_OFFSET);
    }

    function getFee(UniswapV3Config config) internal pure returns (uint24) {
        return uint24((UniswapV3Config.unwrap(config) & FEE_MASK) >> FEE_OFFSET);
    }

    function getToken0Decimals(UniswapV3Config config) internal pure returns (uint8) {
        return uint8((UniswapV3Config.unwrap(config) & TOKEN0_DECIMALS_MASK) >> TOKEN0_DECIMALS_OFFSET);
    }

    function getToken1Decimals(UniswapV3Config config) internal pure returns (uint8) {
        return uint8((UniswapV3Config.unwrap(config) & TOKEN1_DECIMALS_MASK) >> TOKEN1_DECIMALS_OFFSET);
    }

    function __debug_print(UniswapV3Config config) internal pure {
        console2.logBytes32(bytes32(UniswapV3Config.unwrap(config)));
        console2.log("pool: %s", config.getPool());
        console2.log("validUntil: %s", config.getValidUntil());
        console2.log("twapWindow: %s", config.getTwapWindow());
        console2.log("fee: %s", config.getFee());
        console2.log("token0Decimals: %s", config.getToken0Decimals());
        console2.log("token1Decimals: %s", config.getToken1Decimals());
    }
}
