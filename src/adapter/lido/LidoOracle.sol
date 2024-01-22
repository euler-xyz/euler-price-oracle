// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IStEth} from "src/adapter/lido/IStEth.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing Lido stEth <-> wstEth via the stEth contract.
contract LidoOracle is IEOracle {
    /// @dev The address of Lido staked Ether.
    address public immutable stEth;
    /// @dev The address of Lido wrapped staked Ether.
    address public immutable wstEth;

    constructor(address _stEth, address _wstEth) {
        stEth = _stEth;
        wstEth = _wstEth;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.LidoOracle();
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        if (base == stEth && quote == wstEth) {
            return IStEth(stEth).getSharesByPooledEth(inAmount);
        } else if (base == wstEth && quote == stEth) {
            return IStEth(stEth).getPooledEthByShares(inAmount);
        }
        revert Errors.EOracle_NotSupported(base, quote);
    }
}
