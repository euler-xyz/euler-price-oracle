// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {Ownable} from "@solady/auth/Ownable.sol";
import {IOracle} from "src/interfaces/IOracle.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";

contract EulerMultiOracle is Ownable, IPriceOracle {
    string public constant name = "EulerMultiOracle";
    IOracle public immutable fallbackOracle;

    mapping(address base => mapping(address quote => Strategy)) public strategies;

    struct Strategy {
        address oracle;
        bool useFallback;
    }

    event StrategySet(address indexed base, address indexed quote, Strategy indexed strategy);

    error ArityMismatch();
    error GetQuoteFailed(uint256 inAmount, address base, address quote);
    error NoStrategySet(address base, address quote);
    error NotImplemented();

    constructor(address _fallbackOracle, address _owner) {
        fallbackOracle = IOracle(_fallbackOracle);
        _initializeOwner(_owner);
    }

    function getQuote(uint256 inAmount, address base, address quote) public view override returns (uint256) {
        Strategy memory strategy = strategies[base][quote];
        if (strategy.oracle == address(0)) revert NoStrategySet(base, quote);

        (bool success, uint256 outAmount) = _tryGetQuote(inAmount, base, quote, strategy.oracle);
        if (success) return outAmount;

        if (!strategy.useFallback) revert GetQuoteFailed(inAmount, base, quote);
        (success, outAmount) = _tryGetQuote(inAmount, base, quote, address(fallbackOracle));
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

    function setStrategy(address base, address quote, address oracle, bool useFallback) public onlyOwner {
        Strategy memory strategy = Strategy(oracle, useFallback);
        strategies[base][quote] = strategy;
        emit StrategySet(base, quote, strategy);
    }

    function _tryGetQuote(uint256 inAmount, address base, address quote, address oracle)
        private
        view
        returns (bool, uint256)
    {
        (bool success, bytes memory returnData) =
            oracle.staticcall(abi.encodeCall(IOracle.getQuote, (inAmount, base, quote)));
        if (!success) return (false, 0);

        uint256 outAmount = abi.decode(returnData, (uint256));
        return (true, outAmount);
    }
}
