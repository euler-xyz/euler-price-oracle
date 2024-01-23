// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.23;

// import {ERC4626} from "@solady/tokens/ERC4626.sol";
// import {EFactory} from "@euler-vault/EFactory/EFactory.sol";
// import {IEOracle} from "src/interfaces/IEOracle.sol";
// import {Errors} from "src/lib/Errors.sol";
// import {OracleDescription} from "src/lib/OracleDescription.sol";

// /// @author Euler Labs (https://www.eulerlabs.com/)
// /// @notice Adapter for pricing ERC4626 tokens.
// contract NestedVaultOracle is IEOracle {
//     address public immutable eFactory;

//     constructor(address _eFactory) {
//         eFactory = _eFactory;
//     }

//     function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
//         return _getQuote(inAmount, base, quote);
//     }

//     function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
//         uint256 outAmount = _getQuote(inAmount, base, quote);
//         return (outAmount, outAmount);
//     }

//     function description() external view returns (OracleDescription.Description memory description) {}

//     function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
//         // the base vault: vault = eWETH, asset = WETH
//         // (1) nest vault: vault = eeWETH, asset = eWETH

//         // we price eeWETH in terms of WETH, so base = eeWETH, quote = WETH

//         while (EFactory(eFactory).isProxy(base)) {
//             inAmount = ERC4626(base).convertToAssets(inAmount);
//             base = ERC4626(base).asset();
//         }

//         if (base == quote) return inAmount;

//         if (base == reth && quote == weth) {
//             return IReth(reth).getEthValue(inAmount);
//         } else if (base == weth && quote == reth) {
//             return IReth(reth).getRethValue(inAmount);
//         }
//         revert Errors.EOracle_NotSupported(base, quote);
//     }
// }
