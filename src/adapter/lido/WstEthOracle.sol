// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IWstEth} from "src/adapter/lido/IWstEth.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract WstEthOracle is IPriceOracle {
    address public immutable stEth;
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
        if (base == stEth && quote == wstEth) {
            uint256 rate = IWstEth(wstEth).tokensPerStEth();
            return inAmount * rate / 1e18;
        }

        if (base == wstEth && quote == stEth) {
            uint256 rate = IWstEth(wstEth).stEthPerToken();
            return inAmount * rate / 1e18;
        }

        revert Errors.NotSupported(base, quote);
    }
}
