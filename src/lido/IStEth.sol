// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

interface IStEth {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);
}
