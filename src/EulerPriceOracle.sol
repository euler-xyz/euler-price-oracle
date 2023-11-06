// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable} from "@solady/auth/Ownable.sol";

import {ConfigurableUniswapV3Adapter} from "src/adapters/ConfigurableUniswapV3Adapter.sol";
import {IAdapter} from "src/interfaces/IAdapter.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";

contract EulerPriceOracle is Ownable, IPriceOracle {
    string public constant name = "EulerPriceOracle";
    ConfigurableUniswapV3Adapter public immutable uniswapV3Adapter;
    mapping(address base => mapping(address quote => address adapter)) public quoteAdapters;

    event AdapterSet(address indexed base, address indexed quote, address indexed adapter);

    error ArityMismatch();
    error NoAdapterSet(address base, address quote);
    error NotImplemented();

    constructor(address _uniswapV3Adapter) {
        _initializeOwner(msg.sender);
        uniswapV3Adapter = ConfigurableUniswapV3Adapter(_uniswapV3Adapter);
    }

    function getQuote(uint256 inAmount, address base, address quote) external view override returns (uint256) {
        address adapter = quoteAdapters[base][quote];
        if (adapter == address(0)) revert NoAdapterSet(base, quote);

        return IAdapter(adapter).getQuote(inAmount, base, quote);
    }

    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        address adapter = quoteAdapters[base][quote];
        if (adapter == address(0)) revert NoAdapterSet(base, quote);

        uint256 outAmount = IAdapter(adapter).getQuote(inAmount, base, quote);
        return (outAmount, outAmount);
    }

    function getTick(uint256, address, address) external pure returns (uint256) {
        revert NotImplemented();
    }

    function getTicks(uint256, address, address) external pure returns (uint256, uint256) {
        revert NotImplemented();
    }

    function setAdapter(address base, address quote, address adapter) public onlyOwner {
        quoteAdapters[base][quote] = adapter;
        emit AdapterSet(base, quote, adapter);
    }

    function setAdapters(address[] calldata bases, address[] calldata quotes, address[] calldata adapters)
        external
        onlyOwner
    {
        if (bases.length != quotes.length || quotes.length != adapters.length) {
            revert ArityMismatch();
        }

        uint256 length = bases.length;
        for (uint256 i = 0; i < length;) {
            setAdapter(bases[i], quotes[i], adapters[i]);
            unchecked {
                ++i;
            }
        }
    }
}
