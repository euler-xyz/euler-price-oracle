// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IHourglassDepositor {
    function creationBlock() external view returns (uint256);
    function deposit(uint256 amount, bool receiveSplit) external;
    function depositFor(address user, uint256 amount, bool receiveSplit) external;
    function depositTo(address principalRecipient, address pointRecipient, uint256 amount, bool receiveSplit)
        external;
    function enter(uint256 amountToBeDeposited) external;
    function factory() external view returns (address);
    function getPointToken() external view returns (address);
    function getPrincipalToken() external view returns (address);
    function getTokens() external view returns (address[] memory);
    function getUnderlying() external view returns (address);
    function maturity() external view returns (uint256);
    function recombine(uint256 amount) external;
    function recoverToken(address token, address rewardsDistributor) external returns (uint256 amount);
    function redeem(uint256 amount) external;
    function redeemPrincipal(uint256 amount) external;
    function setMaxDeposits(uint256 _depositCap) external;
    function split(uint256 amount) external;

    event Deposit(address user, uint256 amount);
    event DepositedTo(address principalRecipient, address pointRecipient, uint256 amount);
    event Initialized(uint64 version);
    event NewMaturityCreated(address combined, address principal, address yield);
    event Recombine(address user, uint256 amount);
    event Redeem(address user, uint256 amount);
    event Split(address user, uint256 amount);

    error AddressEmptyCode(address target);
    error AddressInsufficientBalance(address account);
    error AlreadyEntered();
    error AmountMismatch();
    error CallerNotEntrant();
    error DepositCapExceeded();
    error FailedInnerCall();
    error InsufficientAssetSupplied();
    error InsufficientDeposit();
    error InsufficientFunds();
    error InvalidDecimals();
    error InvalidInitialization();
    error InvalidMaturity();
    error InvalidUnderlying();
    error Matured();
    error NoCode();
    error NotEntered();
    error NotInitializing();
    error PrematureRedeem();
    error RecipientMismatch();
    error SafeERC20FailedOperation(address token);
    error UnauthorizedCaller();
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
