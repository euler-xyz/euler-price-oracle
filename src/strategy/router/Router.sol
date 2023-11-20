// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IOracle} from "src/interfaces/IOracle.sol";

abstract contract Router is IOracle {
    mapping(address base => mapping(address quote => IOracle)) public oracles;

    error ArityMismatch(uint256 arityA, uint256 arityB, uint256 arityC);

    constructor(address[] memory _bases, address[] memory _quotes, address[] memory _oracles) {
        if (_bases.length != _quotes.length || _quotes.length != _oracles.length) {
            revert ArityMismatch(_bases.length, _quotes.length, _oracles.length);
        }

        uint256 length = _bases.length;

        for (uint256 i = 0; i < length;) {
            address base = _bases[i];
            address quote = _quotes[i];
            address oracle = _oracles[i];

            oracles[base][quote] = IOracle(oracle);

            unchecked {
                ++i;
            }
        }
    }

    function getQuote(uint256 inAmount, address base, address quote) external view virtual returns (uint256) {}
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        virtual
        returns (uint256, uint256)
    {}
}
