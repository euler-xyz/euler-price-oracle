// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

interface IStEth {
    function getPooledEthByShares(uint256) external view returns (uint256);
    function getSharesByPooledEth(uint256) external view returns (uint256);
}
