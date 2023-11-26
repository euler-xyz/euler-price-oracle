// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {ImmutableAddressArray} from "src/lib/ImmutableAddressArray.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {Router} from "src/strategy/router/Router.sol";

contract ImmutableRouter is IPriceOracle, ImmutableAddressArray {
    address public immutable quote;
    address public immutable fallbackOracle;

    constructor(address _quote, address[] memory _baseOraclePairs, address _fallbackOracle)
        ImmutableAddressArray(_baseOraclePairs)
    {
        uint256 length = _baseOraclePairs.length;
        if (length < 2) revert Errors.Router_MalformedPairs(length);
        if (length % 2 != 0) revert Errors.Arity2Mismatch(length / 2, length / 2 + 1);
        quote = _quote;
        fallbackOracle = _fallbackOracle;
    }

    function getQuote(uint256 inAmount, address base, address _quote) external view override returns (uint256) {
        if (_quote != quote) revert Errors.PriceOracle_NotSupported(base, _quote);
        address oracle = _getOracle(base);
        return IPriceOracle(oracle).getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address _quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        if (_quote != quote) revert Errors.PriceOracle_NotSupported(base, _quote);
        address oracle = _getOracle(base);
        return IPriceOracle(oracle).getQuotes(inAmount, base, quote);
    }

    function _getOracle(address base) private view returns (address) {
        uint256 index = _arrayFind(base);
        if (index == type(uint256).max) {
            if (fallbackOracle == address(0)) {
                revert Errors.PriceOracle_NotSupported(base, quote);
            }
            return fallbackOracle;
        }
        address oracle = _arrayGet(index + 1);
        if (oracle == address(0)) {
            if (fallbackOracle == address(0)) {
                revert Errors.PriceOracle_NotSupported(base, quote);
            }
            return fallbackOracle;
        }
        return oracle;
    }

    function description() external pure override returns (OracleDescription.Description memory) {
        return OracleDescription.FallbackRouter();
    }
}
