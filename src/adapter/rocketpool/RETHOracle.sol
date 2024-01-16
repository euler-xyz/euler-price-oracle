// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IReth} from "src/adapter/rocketpool/IReth.sol";
import {BaseOracle} from "src/BaseOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract RethOracle is BaseOracle {
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
        uint256 outAmount;
        if (base == reth && quote == weth) {
            outAmount = IReth(reth).getEthValue(inAmount);
        } else if (base == weth && quote == reth) {
            outAmount = IReth(reth).getRethValue(inAmount);
        } else {
            revert Errors.EOracle_NotSupported(base, quote);
        }

        return outAmount;
    }
}
