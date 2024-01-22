// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IWstEth} from "src/adapter/lido/IWstEth.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Adapter for pricing Lido stEth <-> wstEth via the wstEth contract.
contract WstEthOracle is IEOracle {
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
        return OracleDescription.WstEthOracle();
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        uint256 rate;
        if (base == stEth && quote == wstEth) {
            rate = IWstEth(wstEth).tokensPerStEth();
        } else if (base == wstEth && quote == stEth) {
            rate = IWstEth(wstEth).stEthPerToken();
        } else {
            revert Errors.EOracle_NotSupported(base, quote);
        }

        return inAmount * rate / 1e18;
    }
}
