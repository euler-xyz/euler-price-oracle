// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IOracle} from "src/interfaces/IOracle.sol";
import {Router} from "src/strategy/router/Router.sol";

contract FallbackRouter is Router {
    IOracle public immutable fallbackOracle;

    constructor(address[] memory _bases, address[] memory _quotes, address[] memory _oracles, address _fallbackOracle)
        Router(_bases, _quotes, _oracles)
    {
        fallbackOracle = IOracle(_fallbackOracle);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        IOracle oracle = oracles[base][quote];
        if (address(oracle) == address(0)) oracle = fallbackOracle;
        return oracle.getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        IOracle oracle = oracles[base][quote];
        if (address(oracle) == address(0)) oracle = fallbackOracle;
        return oracle.getQuotes(inAmount, base, quote);
    }
}
