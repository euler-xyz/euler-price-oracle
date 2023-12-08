// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseOracle} from "src/BaseOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {TryCallOracle} from "src/strategy/TryCallOracle.sol";

/// @author totomanov
/// @notice Query up to 3 oracles in order and return the first successful answer.
/// @dev Uses `ImmutableAddressArray` to save on SLOADs. Supports up to 8 oracles.
contract ImmutableLinearStrategy is BaseOracle, TryCallOracle {
    /// @inheritdoc IEOracle
    /// @dev Reverts if the list of oracles is exhausted without a successful answer.
    /// @return The first successful quote.
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        address oracle = _oracle1();
        if (oracle == address(0)) revert Errors.EOracle_NoAnswer();
        (bool success, uint256 answer) = _tryGetQuote(IEOracle(oracle), inAmount, base, quote);
        if (success) return answer;

        oracle = _oracle2();
        if (oracle == address(0)) revert Errors.EOracle_NoAnswer();
        (success, answer) = _tryGetQuote(IEOracle(oracle), inAmount, base, quote);
        if (success) return answer;

        oracle = _oracle3();
        if (oracle == address(0)) revert Errors.EOracle_NoAnswer();
        (success, answer) = _tryGetQuote(IEOracle(oracle), inAmount, base, quote);
        if (success) return answer;

        revert Errors.EOracle_NoAnswer();
    }

    /// @inheritdoc IEOracle
    /// @dev Reverts if the list of oracles is exhausted without a successful answer.
    /// @return The first successful quote.
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        address oracle = _oracle1();
        if (oracle == address(0)) revert Errors.EOracle_NoAnswer();
        (bool success, uint256 bid, uint256 ask) = _tryGetQuotes(IEOracle(oracle), inAmount, base, quote);
        if (success) return (bid, ask);

        oracle = _oracle2();
        if (oracle == address(0)) revert Errors.EOracle_NoAnswer();
        (success, bid, ask) = _tryGetQuotes(IEOracle(oracle), inAmount, base, quote);
        if (success) return (bid, ask);

        oracle = _oracle3();
        if (oracle == address(0)) revert Errors.EOracle_NoAnswer();
        (success, bid, ask) = _tryGetQuotes(IEOracle(oracle), inAmount, base, quote);
        if (success) return (bid, ask);

        revert Errors.EOracle_NoAnswer();
    }

    /// @inheritdoc IEOracle
    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.LinearStrategy();
    }

    function _oracle1() internal pure returns (address oracle) {
        assembly ("memory-safe") {
            oracle := shr(96, calldataload(sub(calldatasize(), 92)))
        }
    }

    function _oracle2() internal pure returns (address oracle) {
        assembly ("memory-safe") {
            oracle := shr(96, calldataload(sub(calldatasize(), 72)))
        }
    }

    function _oracle3() internal pure returns (address oracle) {
        assembly ("memory-safe") {
            oracle := shr(96, calldataload(sub(calldatasize(), 52)))
        }
    }
}
