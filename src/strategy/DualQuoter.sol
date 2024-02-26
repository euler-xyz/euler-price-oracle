// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IEOracle} from "src/interfaces/IEOracle.sol";
import {GovEOracle} from "src/GovEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @title DualQuoter
/// @author Euler Labs (https://www.eulerlabs.com/)
contract DualQuoter is GovEOracle {
    mapping(address => mapping(address => address[2])) public oracles;

    event ConfigSet(address indexed base, address indexed quote, address[2] oracles);

    function govSetConfig(address base, address quote, address[2] memory _oracles) external onlyGovernor {
        oracles[base][quote] = _oracles;
        emit ConfigSet(base, quote, _oracles);
    }

    function govClearConfig(address base, address quote) external onlyGovernor {
        delete oracles[base][quote];
        emit ConfigSet(base, quote, [address(0), address(0)]);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        (uint256 outAmount0, uint256 outAmount1) = _getDualQuotes(inAmount, base, quote);
        return (outAmount0 + outAmount1) / 2;
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        (uint256 outAmount0, uint256 outAmount1) = _getDualQuotes(inAmount, base, quote);
        return outAmount0 < outAmount1 ? (outAmount0, outAmount1) : (outAmount1, outAmount0);
    }

    /// @inheritdoc IEOracle
    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.FallbackRouter(governor);
    }

    function _getDualQuotes(uint256 inAmount, address base, address quote) internal view returns (uint256, uint256) {
        address[2] memory _oracles = oracles[base][quote];
        if (_oracles[0] == address(0)) revert Errors.EOracle_NotSupported(base, quote);

        uint256 outAmount0 = IEOracle(_oracles[0]).getQuote(inAmount, base, quote);
        uint256 outAmount1 = IEOracle(_oracles[1]).getQuote(inAmount, base, quote);
        return (outAmount0, outAmount1);
    }
}
