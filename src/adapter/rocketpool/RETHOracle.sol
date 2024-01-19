// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IReth} from "src/adapter/rocketpool/IReth.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract RethOracle {
    address public immutable weth;
    address public immutable reth;

    constructor(address _weth, address _reth) {
        weth = _weth;
        reth = _reth;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        return _getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 outAmount = _getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.RethOracle();
    }

    function _getQuote(uint256 inAmount, address base, address quote) private view returns (uint256) {
        if (base == reth && quote == weth) {
            return IReth(reth).getEthValue(inAmount);
        } else if (base == weth && quote == reth) {
            return IReth(reth).getRethValue(inAmount);
        }
        revert Errors.EOracle_NotSupported(base, quote);
    }
}
