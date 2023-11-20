// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IOracle} from "src/interfaces/IOracle.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";

contract LinearStrategy is IOracle, ImmutableAddressArray {
    error NoAnswer();

    constructor(address[] memory _oracles) ImmutableAddressArray(_oracles) {}

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        for (uint256 i = 0; i < cardinality;) {
            IOracle oracle = IOracle(_get(i));

            (bool success, uint256 answer) = _tryGetQuote(oracle, inAmount, base, quote);
            if (success) return answer;

            unchecked {
                ++i;
            }
        }

        revert NoAnswer();
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        for (uint256 i = 0; i < cardinality;) {
            IOracle oracle = IOracle(_get(i));

            (bool success, uint256 bid, uint256 ask) = _tryGetQuotes(oracle, inAmount, base, quote);
            if (success) return (bid, ask);

            unchecked {
                ++i;
            }
        }

        revert NoAnswer();
    }

    function _tryGetQuote(IOracle oracle, uint256 inAmount, address base, address quote)
        private
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
        private
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
