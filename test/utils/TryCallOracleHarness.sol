// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IOracle} from "src/interfaces/IOracle.sol";
import {TryCallOracle} from "src/strategy/TryCallOracle.sol";

contract TryCallOracleHarness is TryCallOracle {
    function tryGetQuote(IOracle oracle, uint256 inAmount, address base, address quote)
        external
        view
        returns (bool, /* success */ uint256 /* outAmount */ )
    {
        return _tryGetQuote(oracle, inAmount, base, quote);
    }

    function tryGetQuotes(IOracle oracle, uint256 inAmount, address base, address quote)
        external
        view
        returns (bool, /* success */ uint256, /* askOut */ uint256 /* askOut */ )
    {
        return _tryGetQuotes(oracle, inAmount, base, quote);
    }
}
