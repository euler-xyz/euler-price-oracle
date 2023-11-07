// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable} from "@solady/auth/Ownable.sol";
import {IAdapter} from "src/interfaces/IAdapter.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";

contract EulerPriceOracle is Ownable, IPriceOracle {
    string public constant name = "EulerPriceOracle";
    IAdapter public immutable fallbackAdapter;

    mapping(address base => mapping(address quote => Strategy)) public strategies;

    struct Strategy {
        address adapter;
        bool useFallback;
    }

    event StrategySet(address indexed base, address indexed quote, Strategy indexed strategy);

    error ArityMismatch();
    error GetQuoteFailed(uint256 inAmount, address base, address quote);
    error NoStrategySet(address base, address quote);
    error NotImplemented();

    constructor(address _fallbackAdapter, address _owner) {
        fallbackAdapter = IAdapter(_fallbackAdapter);
        _initializeOwner(_owner);
    }

    function getQuote(uint256 inAmount, address base, address quote) public view override returns (uint256) {
        Strategy memory strategy = strategies[base][quote];
        if (strategy.adapter == address(0)) revert NoStrategySet(base, quote);

        (bool success, uint256 outAmount) = _tryGetQuote(inAmount, base, quote, strategy.adapter);
        if (success) return outAmount;
        if (!strategy.useFallback) revert GetQuoteFailed(inAmount, base, quote);

        (success, outAmount) = _tryGetQuote(inAmount, base, quote, address(fallbackAdapter));
        if (success) return outAmount;
        revert GetQuoteFailed(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        uint256 outAmount = getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function getTick(uint256, address, address) external pure returns (uint256) {
        revert NotImplemented();
    }

    function getTicks(uint256, address, address) external pure returns (uint256, uint256) {
        revert NotImplemented();
    }

    function setStrategy(address base, address quote, address adapter, bool useFallback) public onlyOwner {
        Strategy memory strategy = Strategy(adapter, useFallback);
        strategies[base][quote] = strategy;
        emit StrategySet(base, quote, strategy);
    }

    function _tryGetQuote(uint256 inAmount, address base, address quote, address adapter)
        private
        view
        returns (bool, uint256)
    {
        (bool success, bytes memory returnData) =
            adapter.staticcall(abi.encodeCall(IAdapter.getQuote, (inAmount, base, quote)));
        if (!success) return (false, 0);

        uint256 outAmount = abi.decode(returnData, (uint256));
        return (true, outAmount);
    }
}
