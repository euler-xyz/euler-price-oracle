// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";
import {TryCallOracle} from "src/strategy/TryCallOracle.sol";

contract ConstantBackoffLinearStrategy is TryCallOracle, ImmutableAddressArray {
    uint256 public immutable backOff;
    PackedUint32Array public cooldowns;

    constructor(address[] memory _oracles, uint256 _backoff) ImmutableAddressArray(_oracles) {
        backOff = _backoff;
    }

    function getQuote(uint256 inAmount, address base, address quote) external returns (uint256) {
        PackedUint32Array _cooldowns = cooldowns;

        for (uint256 i = 0; i < cardinality; ++i) {
            uint256 cooldown = _cooldowns.get(i);
            if (cooldown > block.timestamp) continue;

            IPriceOracle oracle = IPriceOracle(_get(i));

            (bool success, uint256 answer) = _tryGetQuote(oracle, inAmount, base, quote);
            if (success) {
                _updateCooldowns(_cooldowns);
                return answer;
            } else {
                cooldowns.set(i, block.timestamp + backOff);
            }
        }

        _updateCooldowns(_cooldowns);
        return 0;
    }

    function getQuotes(uint256 inAmount, address base, address quote) external returns (uint256, uint256) {
        PackedUint32Array _cooldowns = cooldowns;

        for (uint256 i = 0; i < cardinality;) {
            uint256 cooldown = _cooldowns.get(i);
            if (cooldown > block.timestamp) continue;

            IPriceOracle oracle = IPriceOracle(_get(i));

            (bool success, uint256 bid, uint256 ask) = _tryGetQuotes(oracle, inAmount, base, quote);
            if (success) {
                _updateCooldowns(_cooldowns);
                return (bid, ask);
            } else {
                cooldowns.set(i, block.timestamp + backOff);
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
