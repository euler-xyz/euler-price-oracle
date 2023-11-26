// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

abstract contract Router is IPriceOracle {
    mapping(address base => mapping(address quote => IPriceOracle)) public oracles;

    constructor(address[] memory _bases, address[] memory _quotes, address[] memory _oracles) {
        if (_bases.length != _quotes.length || _quotes.length != _oracles.length) {
            revert Errors.Arity3Mismatch(_bases.length, _quotes.length, _oracles.length);
        }

        uint256 length = _bases.length;

        for (uint256 i = 0; i < length;) {
            address base = _bases[i];
            address quote = _quotes[i];
            address oracle = _oracles[i];

            oracles[base][quote] = IPriceOracle(oracle);

            unchecked {
                ++i;
            }
        }
    }

    function getQuote(uint256 inAmount, address base, address quote) external view virtual returns (uint256);
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        virtual
        returns (uint256, uint256);

    function description() external view virtual returns (OracleDescription.Description memory);
}
