// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {ERC4626} from "@solady/tokens/ERC4626.sol";
import {EFactory} from "@euler-vault/EFactory/EFactory.sol";
import {GovEOracle} from "src/GovEOracle.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

/// @author Euler Labs (https://www.eulerlabs.com/)
/// @notice Default Oracle resolver for Euler Axiom Vaults.
contract AxiomRouter is GovEOracle {
    address public immutable eFactory;
    address public fallbackOracle;
    mapping(address base => mapping(address quote => address)) public oracles;

    event ConfigSet(address indexed base, address indexed quote, address indexed oracle);
    event ConfigUnset(address indexed base, address indexed quote);
    event FallbackOracleSet(address indexed fallbackOracle);

    constructor(address _eFactory) {
        eFactory = _eFactory;
    }

    function govSetConfig(address base, address quote, address oracle) external onlyGovernor {
        oracles[base][quote] = oracle;
        emit ConfigSet(base, quote, oracle);
    }

    function govUnsetConfig(address base, address quote) external onlyGovernor {
        delete oracles[base][quote];
        emit ConfigUnset(base, quote);
    }

    function govSetFallbackOracle(address _fallbackOracle) external onlyGovernor {
        fallbackOracle = _fallbackOracle;
        emit FallbackOracleSet(_fallbackOracle);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        address oracle;
        (inAmount, base, quote, oracle) = _resolveOracle(inAmount, base, quote);
        if (base == quote) return inAmount;
        return IEOracle(oracle).getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        address oracle;
        (inAmount, base, quote, oracle) = _resolveOracle(inAmount, base, quote);
        if (base == quote) return (inAmount, inAmount);
        return IEOracle(oracle).getQuotes(inAmount, base, quote);
    }

    function description() external view override returns (OracleDescription.Description memory) {
        return OracleDescription.SimpleRouter(governor);
    }

    function _resolveOracle(uint256 inAmount, address base, address quote)
        internal
        view
        returns (uint256, address, address, address)
    {
        if (base == quote) return (inAmount, base, quote, address(0));
        address oracle = oracles[base][quote];
        if (oracle != address(0)) return (inAmount, base, quote, oracle);

        if (EFactory(eFactory).isProxy(base)) {
            return _resolveOracle(ERC4626(base).convertToAssets(inAmount), ERC4626(base).asset(), quote);
        }
        if (EFactory(eFactory).isProxy(quote)) {
            return _resolveOracle(ERC4626(quote).convertToShares(inAmount), base, ERC4626(quote).asset());
        } else {
            oracle = fallbackOracle;
            if (oracle == address(0)) revert Errors.EOracle_NotSupported(base, quote);
        }

        return (inAmount, base, quote, oracle);
    }
}
