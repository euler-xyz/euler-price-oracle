// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IOracle} from "src/interfaces/IOracle.sol";

abstract contract TryCallOracle {
    function _tryGetQuote(IOracle oracle, uint256 inAmount, address base, address quote)
        internal
        view
        returns (bool, /* success */ uint256 /* outAmount */ )
    {
        try oracle.getQuote(inAmount, base, quote) returns (uint256 outAmount) {
            return (true, outAmount);
        } catch {
            return (false, 0);
        }
    }

    function _tryGetQuotes(IOracle oracle, uint256 inAmount, address base, address quote)
        internal
        view
        returns (bool, /* success */ uint256, /* askOut */ uint256 /* askOut */ )
    {
        try oracle.getQuotes(inAmount, base, quote) returns (uint256 bidOut, uint256 askOut) {
            return (true, bidOut, askOut);
        } catch {
            return (false, 0, 0);
        }
    }
}
