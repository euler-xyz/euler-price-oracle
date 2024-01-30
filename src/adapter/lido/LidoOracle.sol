// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IStEth} from "src/adapter/lido/IStEth.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @title LidoOracle
/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing Lido stEth <-> wstEth via the stEth contract.
contract LidoOracle is IEOracle {
    /// @dev The address of Lido staked Ether.
    address public immutable stEth;
    /// @dev The address of Lido wrapped staked Ether.
    address public immutable wstEth;

    /// @notice Deploy an ERC4626Oracle.
    /// @param _stEth The address of Lido staked Ether.
    /// @param _wstEth The address of Lido wrapped staked Ether.
    /// @dev The oracle will support stEth/wstEth and wstEth/stEth pricing.
    constructor(address _stEth, address _wstEth) {
        stEth = _stEth;
        wstEth = _wstEth;
    }

    /// @inheritdoc IEOracle
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    /// @inheritdoc IEOracle
    /// @dev Does not support true bid-ask pricing.
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    /// @inheritdoc IEOracle
    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.LidoOracle();
    }

    /// @notice Get a quote by querying the exchange rate from the stEth contract.
    /// @dev Calls `getSharesByPooledEth` for stEth/wstEth and `getPooledEthByShares` for wstEth/stEth.
    /// @param inAmount The amount of `base` to convert.
    /// @param base The token that is being priced. Either `stEth` or `wstEth`.
    /// @param quote The token that is the unit of account. Either `wstEth` or `stEth`.
    /// @return The converted amount.
    function _getQuote(uint256 inAmount, address base, address quote) internal view returns (uint256) {
        if (base == stEth && quote == wstEth) {
            return IStEth(stEth).getSharesByPooledEth(inAmount);
        } else if (base == wstEth && quote == stEth) {
            return IStEth(stEth).getPooledEthByShares(inAmount);
        }
        revert Errors.EOracle_NotSupported(base, quote);
    }
}
