// // SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.23;

// import {MockWstEth} from "test/utils/MockWstEth.sol";
// import {WstEthOracle} from "src/adapter/lido/WstEthOracle.sol";
// import {IEOracle} from "src/interfaces/IEOracle.sol";

// contract WstEthOracleEchidnaTest {
//     address internal constant GOVERNOR = address(0xb055);
//     address internal constant STETH = address(0x1111);
//     MockWstEth internal immutable WSTETH;
//     WstEthOracle internal immutable oracle;

//     constructor() {
//         WSTETH = new MockWstEth();
//         oracle = new WstEthOracle(STETH, address(WSTETH));
//         oracle.initialize(GOVERNOR);
//     }

//     function testFuzz_GetQuote_NeverReturnsZero(uint256 stEthPerToken, uint256 tokensPerStEth, uint256 inAmount)
//         public
//         returns (bool)
//     {
//         WSTETH.setStEthPerToken(stEthPerToken);
//         WSTETH.setTokensPerStEth(tokensPerStEth);

//         uint256 outAmount = oracle.getQuote(inAmount, address(WSTETH), STETH);
//         return outAmount > 0;
//     }
// }
