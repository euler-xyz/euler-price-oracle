// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHourglassDepositor {
    function getTokens() external view returns (address[] memory);
    function getUnderlying() external view returns (address);
    function maturity() external view returns (uint256);
}

interface IVedaDepositor {
    function mintLockedUnderlying(address depositAsset, uint256 amountOutMinBps) external returns (uint256 amountOut);
}

interface IEthFiLUSDDepositor {
    function mintLockedUnderlying(uint256 minMintReceivedSlippageBps, address lusdDepositAsset, address sourceOfFunds)
        external
        returns (uint256 amountDepositAssetMinted);
}

interface IEthFiLiquidDepositor {
    function mintLockedUnderlying(uint256 minMintReceivedSlippageBps, address lusdDepositAsset, address sourceOfFunds)
        external
        returns (uint256 amountDepositAssetMinted);
}
