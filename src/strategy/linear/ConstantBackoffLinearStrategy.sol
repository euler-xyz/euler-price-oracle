// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {TryCallOracle} from "src/strategy/TryCallOracle.sol";

/// @author totomanov
/// @notice Query up to 8 oracles in order and return the first successful answer.
/// Failed oracles are backed off for a pre-configured number of seconds.
/// During the backoff period the oracle is skipped.
/// @dev Uses `ImmutableAddressArray` to save on SLOADs. Supports up to 8 oracles.
/// IMPORTANT INTEGRATOR NOTE: `getQuote` and `getQuotes` are NOT view methods.
/// They do not revert but return 0 if the list is exhausted without a successful answer.
/// This is because `cooldowns` may need to be updated in storage during execution.
contract ConstantBackoffLinearStrategy is TryCallOracle, ImmutableAddressArray {
    PackedUint32Array public immutable backoffs;
    PackedUint32Array public cooldowns;

    /// @notice Deploy a new LinearStrategy.
    /// @param _oracles The oracles to try in the given order.
    /// @param _backoffs The number of seconds to wait before retrying an oracle.
    /// Backoff indices correspond to oracles indices.
    constructor(address[] memory _oracles, PackedUint32Array _backoffs) ImmutableAddressArray(_oracles) {
        backoffs = _backoffs;
    }

    /// @dev IMPORTANT INTEGRATOR NOTE: `getQuote` and `getQuotes` are NOT view methods.
    /// They do not revert but return 0 if the list is exhausted without a successful answer.
    /// This is because `cooldowns` may need to be updated in storage during execution.
    /// @return The first successful quote or 0 if no valid answer was returned.
    function getQuote(uint256 inAmount, address base, address quote) external returns (uint256) {
        PackedUint32Array _cooldowns = cooldowns;

        for (uint256 i = 0; i < cardinality; ++i) {
            // Skip the oracle if it's backed off.
            uint256 cooldown = _cooldowns.get(i);
            if (cooldown > block.timestamp) continue;

            IPriceOracle oracle = IPriceOracle(_arrayGet(i));

            (bool success, uint256 answer) = _tryGetQuote(oracle, inAmount, base, quote);
            if (success) {
                _updateCooldowns(_cooldowns);
                return answer;
            } else {
                cooldowns.set(i, block.timestamp + backoffs.get(i));
            }
        }

        _updateCooldowns(_cooldowns);
        return 0;
    }

    /// @dev IMPORTANT INTEGRATOR NOTE: `getQuote` and `getQuotes` are NOT view methods.
    /// They do not revert but return 0 if the list is exhausted without a successful answer.
    /// This is because `cooldowns` may need to be updated in storage during execution.
    /// @return The first successful quote or 0 if no valid answer was returned.
    function getQuotes(uint256 inAmount, address base, address quote) external returns (uint256, uint256) {
        PackedUint32Array _cooldowns = cooldowns;

        for (uint256 i = 0; i < cardinality;) {
            uint256 cooldown = _cooldowns.get(i);
            if (cooldown > block.timestamp) continue;

            IPriceOracle oracle = IPriceOracle(_arrayGet(i));

            (bool success, uint256 bid, uint256 ask) = _tryGetQuotes(oracle, inAmount, base, quote);
            if (success) {
                _updateCooldowns(_cooldowns);
                return (bid, ask);
            } else {
                cooldowns.set(i, block.timestamp + backoffs.get(i));
            }

            unchecked {
                ++i;
            }
        }

        _updateCooldowns(_cooldowns);
        return (0, 0);
    }

    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.ConstantBackoffLinearStrategy();
    }

    function _updateCooldowns(PackedUint32Array _cooldowns) internal {
        if (cooldowns.neq(_cooldowns)) cooldowns = _cooldowns;
    }
}
