// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Ownable} from "@solady/auth/Ownable.sol";

import {GovernedUniswapV3Adapter} from "src/uniswap/GovernedUniswapV3Adapter.sol";
import {IAdapter} from "src/interfaces/IAdapter.sol";
import {IPriceOracle} from "src/interfaces/IPriceOracle.sol";

contract EulerPriceOracle is Ownable, IPriceOracle {
    string public constant name = "EulerPriceOracle";
    GovernedUniswapV3Adapter public immutable uniswapV3Adapter;
    mapping(address base => mapping(address quote => address adapter)) public primaryAdapters;
    mapping(address base => mapping(address quote => address adapter)) public fallbackAdapters;

    event AdapterSet(address indexed base, address indexed quote, address indexed adapter);

    error ArityMismatch();
    error CouldNotGetPrice(uint256 inAmount, address base, address quote);
    error NoAdapterSet(address base, address quote);
    error NotImplemented();

    constructor(address _uniswapV3Adapter, address _owner) {
        uniswapV3Adapter = GovernedUniswapV3Adapter(_uniswapV3Adapter);
        _initializeOwner(_owner);
    }

    function getQuote(uint256 inAmount, address base, address quote) public view override returns (uint256) {
        _tryAdapter(inAmount, base, quote, primaryAdapters);
        _tryAdapter(inAmount, base, quote, fallbackAdapters);

        revert CouldNotGetPrice(inAmount, base, quote);
    }

    function getQuotes(uint256, address, address) external pure override returns (uint256, uint256) {
        revert NotImplemented();
    }

    function getTick(uint256, address, address) external pure returns (uint256) {
        revert NotImplemented();
    }

    function getTicks(uint256, address, address) external pure returns (uint256, uint256) {
        revert NotImplemented();
    }

    function setAdapter(address base, address quote, address adapter, bool isPrimary) public onlyOwner {
        mapping(address => mapping(address => address)) storage adapters =
            isPrimary ? primaryAdapters : fallbackAdapters;
        adapters[base][quote] = adapter;
        emit AdapterSet(base, quote, adapter);
    }

    function setAdapters(
        address[] calldata bases,
        address[] calldata quotes,
        address[] calldata adapters,
        bool[] calldata isPrimary
    ) external onlyOwner {
        if (bases.length != quotes.length || quotes.length != adapters.length || adapters.length != isPrimary.length) {
            revert ArityMismatch();
        }

        uint256 length = bases.length;
        for (uint256 i = 0; i < length;) {
            setAdapter(bases[i], quotes[i], adapters[i], isPrimary[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _tryAdapter(
        uint256 inAmount,
        address base,
        address quote,
        mapping(address => mapping(address => address)) storage adapters
    ) private view {
        address adapter = adapters[base][quote];
        if (adapter == address(0)) return;

        (bool success, bytes memory returnData) =
            adapter.staticcall(abi.encodeCall(IAdapter.getQuote, (inAmount, base, quote)));
        if (!success) return;

        uint256 outAmount = abi.decode(returnData, (uint256));
        assembly {
            mstore(0x00, outAmount)
            return(0x00, 0x20)
        }
    }
}
