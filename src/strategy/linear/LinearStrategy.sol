// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseOracle} from "src/BaseOracle.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {TryCallOracle} from "src/strategy/TryCallOracle.sol";

/// @author totomanov
/// @notice Query up to 8 oracles in order and return the first successful answer.
/// @dev Uses `ImmutableAddressArray` to save on SLOADs. Supports up to 8 oracles.
contract LinearStrategy is BaseOracle, TryCallOracle, ImmutableAddressArray {
    /// @notice Deploy a new LinearStrategy.
    /// @param _oracles The oracles to try in the given order.
    constructor(address[] memory _oracles) ImmutableAddressArray(_oracles) {}

    /// @inheritdoc IPriceOracle
    /// @dev Reverts if the list of oracles is exhausted without a successful answer.
    /// @return The first successful quote.
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        for (uint256 i = 0; i < cardinality;) {
            IPriceOracle oracle = IPriceOracle(_arrayGet(i));

            (bool success, uint256 answer) = _tryGetQuote(oracle, inAmount, base, quote);
            if (success) return answer;

            unchecked {
                ++i;
            }
        }

        revert Errors.PriceOracle_NoAnswer();
    }

    /// @inheritdoc IPriceOracle
    /// @dev Reverts if the list of oracles is exhausted without a successful answer.
    /// @return The first successful quote.
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        for (uint256 i = 0; i < cardinality;) {
            IPriceOracle oracle = IPriceOracle(_arrayGet(i));

            (bool success, uint256 bid, uint256 ask) = _tryGetQuotes(oracle, inAmount, base, quote);
            if (success) return (bid, ask);

            unchecked {
                ++i;
            }
        }

        revert Errors.PriceOracle_NoAnswer();
    }

    /// @inheritdoc IPriceOracle
    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.LinearStrategy();
    }
}
