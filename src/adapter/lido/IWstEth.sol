// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IWstEth {
    function stEthPerToken() external view returns (uint256);
    function tokensPerStEth() external view returns (uint256);
}
