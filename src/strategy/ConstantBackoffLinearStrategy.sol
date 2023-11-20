// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IOracle} from "src/interfaces/IOracle.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {PackedUint32Array} from "src/lib/PackedUint32Array.sol";

contract ConstantBackoffLinearStrategy is ImmutableAddressArray {
    uint256 public immutable backOff;
    PackedUint32Array public cooldowns;

    error NoAnswer();

    constructor(address[] memory _oracles, uint256 _backoff) ImmutableAddressArray(_oracles) {
        backOff = _backoff;
    }

    function getQuote(uint256 inAmount, address base, address quote) external returns (uint256) {
        PackedUint32Array _cooldowns = cooldowns;

        for (uint256 i = 0; i < cardinality; ++i) {
            uint256 cooldown = _cooldowns.get(i);
            if (cooldown > block.timestamp) continue;

            IOracle oracle = IOracle(_get(i));

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

            IOracle oracle = IOracle(_get(i));

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

    function _updateCooldowns(PackedUint32Array _cooldowns) internal {
        if (cooldowns.neq(_cooldowns)) cooldowns = _cooldowns;
    }
}
