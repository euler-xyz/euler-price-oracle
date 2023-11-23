// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IOracle} from "src/interfaces/IOracle.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {Router} from "src/strategy/router/Router.sol";

contract SimpleRouter is Router {
    error NoOracleSet(address base, address quote);

    constructor(address[] memory _bases, address[] memory _quotes, address[] memory _oracles)
        Router(_bases, _quotes, _oracles)
    {}

    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        IOracle oracle = oracles[base][quote];
        if (address(oracle) == address(0)) revert NoOracleSet(base, quote);
        return oracle.getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        IOracle oracle = oracles[base][quote];
        if (address(oracle) == address(0)) revert NoOracleSet(base, quote);
        return oracle.getQuotes(inAmount, base, quote);
    }

    function description() external pure override returns (OracleDescription.Description memory) {
        return OracleDescription.SimpleRouter();
    }
}
