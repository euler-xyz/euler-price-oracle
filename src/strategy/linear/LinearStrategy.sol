// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {TryCallOracle} from "src/strategy/TryCallOracle.sol";

contract LinearStrategy is IPriceOracle, TryCallOracle, ImmutableAddressArray {
    constructor(address[] memory _oracles) ImmutableAddressArray(_oracles) {}

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        for (uint256 i = 0; i < cardinality;) {
            IPriceOracle oracle = IPriceOracle(_get(i));

            (bool success, uint256 answer) = _tryGetQuote(oracle, inAmount, base, quote);
            if (success) return answer;

            unchecked {
                ++i;
            }
        }

        revert Errors.NoAnswer();
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        for (uint256 i = 0; i < cardinality;) {
            IPriceOracle oracle = IPriceOracle(_get(i));

            (bool success, uint256 bid, uint256 ask) = _tryGetQuotes(oracle, inAmount, base, quote);
            if (success) return (bid, ask);

            unchecked {
                ++i;
            }
        }

        revert Errors.NoAnswer();
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.LinearStrategy();
    }
}
