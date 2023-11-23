// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

// import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";

// interface ICurve2Pool {
//     function ma_half_time() external view returns (uint256);
//     function price_oracle() external view returns (uint256);
//     function coins(uint256) external view returns (address);
// }

// interface ICurveNPool {
//     function ma_half_time() external view returns (uint256);
//     function price_oracle(uint256) external view returns (uint256);
//     function coins(uint256) external view returns (address);
// }

// interface ICurveRegistry {
//     function get_pool_from_lp_token(address lpToken) view returns (address);
//     function get_balances(address pool) view returns (uint256[8] memory);
//     function get_coins(address pool) view returns (address[8] memory);
// }

// contract CurveLPOracle is IPriceOracle {
//     address public immutable weth;
//     ICurveRegistry public immutable metaRegistry;
//     ICurveRegistry public immutable stableRegistry;
//     mapping(address base => mapping(address quote => CurveConfig)) public configs;

//     struct CurveConfig {
//         address pool;
//         uint8 numTokens;
//     }

//     error NotSupported(address base, address quote);
//     error NoPoolFound(address base, address quote);

//     constructor(address _weth, address _metaRegistry, address _stableRegistry) {
//         weth = _weth;
//         metaRegistry = ICurveRegistry(_metaRegistry);
//         stableRegistry = ICurveRegistry(_stableRegistry);
//     }

//     function initConfig(address base, address quote) external {
//         address pool = metaRegistry.get_pool_from_lp_token(base);
//         if (pool == address(0)) {
//             pool = metaRegistry.get_pool_from_lp_token(quote);
//         }

//         // no such lp token
//         if (pool == address(0)) revert NoPoolFound(base, quote);

//         address[8] memory coins = metaRegistry.get_coins(pool);

//         uint256 index;
//         do {
//             address coin = coins[index];
//             if (coin == address(0)) break;
//             unchecked {
//                 ++index;
//             }
//         } while(index < 8);

//         configs[base][quote] = CurveConfig({
//             pool: pool,
//             numTokens: index
//         });
//     }

//     function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
//         CurveConfig memory config = configs[base][quote];
//         address pool = config.pool;
//         if (pool == address(0)) revert NotSupported(base, quote);

//         uint256 numTokens = config.numTokens;
//         address[8] memory balances = metaRegistry.get_balances(pool);

//         for (uint256 i = 0; i < numTokens;) {

//             unchecked {
//                 ++i;
//             }
//         }

//         if (config.numTokens == 2) {
//             uint256 unitPrice = ICurve2Pool(pool).price_oracle();
//             if (config.quoteIndex == config.refIndex) {
//                 return inAmount * unitPrice / 1e18;
//             }
//             return inAmount * 1e18 / unitPrice;
//         }

//         if (config.quoteIndex == config.refIndex) {
//             uint256 unitPrice = ICurveNPool(pool).price_oracle(config.baseIndex);
//             return inAmount * unitPrice / 1e18;
//         } else if (config.baseIndex == config.refIndex) {
//             uint256 unitPrice = ICurveNPool(pool).price_oracle(config.quoteIndex);
//             return inAmount * 1e18 / unitPrice;
//         } else {
//             uint256 basePrice = ICurveNPool(pool).price_oracle(config.baseIndex);
//             uint256 quotePrice = ICurveNPool(pool).price_oracle(config.quoteIndex);

//             return basePrice * 1e18 / quotePrice;
//         }
//     }

//     function _getAsset(address token) private pure returns (address) {
//         if (token == weth) return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
//         return token;
//     }

//     function _setConfig(address base, address quote, CurveConfig memory config) internal {
//         configs[base][quote] = config;
//     }
// }
