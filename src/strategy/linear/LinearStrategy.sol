// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {BaseOracle} from "src/BaseOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {TryCallOracle} from "src/strategy/TryCallOracle.sol";

/// @author totomanov
/// @notice Query up to 8 oracles in order and return the first successful answer.
contract LinearStrategy is BaseOracle, TryCallOracle {
    address[] public oracles;

    function govSetConfig(address[] memory _oracles) external onlyGovernor {
        uint256 prevLength = oracles.length;
        uint256 nextLength = _oracles.length;

        oracles = new address[](nextLength);
        for (uint256 i = 0; i < nextLength; ++i) {
            oracles[i] = _oracles[i];
        }

        if (nextLength < prevLength) {
            for (uint256 i = nextLength; i < prevLength; ++i) {
                delete oracles[i];
            }
        }
    }

    /// @inheritdoc IEOracle
    /// @dev Reverts if the list of oracles is exhausted without a successful answer.
    /// @return The first successful quote.
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        uint256 cardinality = oracles.length;
        for (uint256 i = 0; i < cardinality;) {
            IEOracle oracle = IEOracle(oracles[i]);

            (bool success, uint256 answer) = _tryGetQuote(oracle, inAmount, base, quote);
            if (success) return answer;

            unchecked {
                ++i;
            }
        }

        revert Errors.EOracle_NoAnswer();
    }

    /// @inheritdoc IEOracle
    /// @dev Reverts if the list of oracles is exhausted without a successful answer.
    /// @return The first successful quote.
    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        uint256 cardinality = oracles.length;
        for (uint256 i = 0; i < cardinality;) {
            IEOracle oracle = IEOracle(oracles[i]);

            (bool success, uint256 bid, uint256 ask) = _tryGetQuotes(oracle, inAmount, base, quote);
            if (success) return (bid, ask);

            unchecked {
                ++i;
            }
        }

        revert Errors.EOracle_NoAnswer();
    }

    /// @inheritdoc IEOracle
    function description() external pure returns (OracleDescription.Description memory) {
        return OracleDescription.LinearStrategy();
    }
}
