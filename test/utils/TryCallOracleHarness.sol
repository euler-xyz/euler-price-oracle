// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {TryCallOracle} from "src/strategy/TryCallOracle.sol";

contract TryCallOracleHarness is TryCallOracle {
    function tryGetQuote(IPriceOracle oracle, uint256 inAmount, address base, address quote)
        external
        view
        returns (bool, /* success */ uint256 /* outAmount */ )
    {
        return _tryGetQuote(oracle, inAmount, base, quote);
    }

    function tryGetQuotes(IPriceOracle oracle, uint256 inAmount, address base, address quote)
        external
        view
        returns (bool, /* success */ uint256, /* askOutAmount */ uint256 /* askOutAmount */ )
    {
        return _tryGetQuotes(oracle, inAmount, base, quote);
    }
}
