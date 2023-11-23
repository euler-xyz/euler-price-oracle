// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";
import {Router} from "src/strategy/router/Router.sol";

contract FallbackRouter is Router {
    IPriceOracle public immutable fallbackOracle;

    constructor(address[] memory _bases, address[] memory _quotes, address[] memory _oracles, address _fallbackOracle)
        Router(_bases, _quotes, _oracles)
    {
        fallbackOracle = IPriceOracle(_fallbackOracle);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        IPriceOracle oracle = oracles[base][quote];
        if (address(oracle) == address(0)) oracle = fallbackOracle;
        return oracle.getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        IPriceOracle oracle = oracles[base][quote];
        if (address(oracle) == address(0)) oracle = fallbackOracle;
        return oracle.getQuotes(inAmount, base, quote);
    }

    function description() external pure override returns (OracleDescription.Description memory) {
        return OracleDescription.FallbackRouter();
    }
}
