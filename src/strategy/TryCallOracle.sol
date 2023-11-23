// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";

abstract contract TryCallOracle {
    function _tryGetQuote(IPriceOracle oracle, uint256 inAmount, address base, address quote)
        internal
        view
        returns (bool, /* success */ uint256 /* outAmount */ )
    {
        (bool success, bytes memory returnData) =
            address(oracle).staticcall(abi.encodeCall(IPriceOracle.getQuote, (inAmount, base, quote)));

        if (!success || returnData.length != 32) return (false, 0);
        uint256 outAmount = abi.decode(returnData, (uint256));
        return (true, outAmount);
    }

    function _tryGetQuotes(IPriceOracle oracle, uint256 inAmount, address base, address quote)
        internal
        view
        returns (bool, /* success */ uint256, /* bidOut */ uint256 /* askOut */ )
    {
        (bool success, bytes memory returnData) =
            address(oracle).staticcall(abi.encodeCall(IPriceOracle.getQuotes, (inAmount, base, quote)));

        if (!success || returnData.length != 64) return (false, 0, 0);
        (uint256 bidOut, uint256 askOut) = abi.decode(returnData, (uint256, uint256));
        return (true, bidOut, askOut);
    }
}
