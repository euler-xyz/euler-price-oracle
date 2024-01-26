// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.23;

import {IPyth} from "@pyth/IPyth.sol";
import {PythStructs} from "@pyth/PythStructs.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {IEOracle} from "src/interfaces/IEOracle.sol";
import {Errors} from "src/lib/Errors.sol";
import {OracleDescription} from "src/lib/OracleDescription.sol";

contract PythOracle is IEOracle {
    IPyth public immutable pyth;
    address public immutable base;
    address public immutable quote;
    bytes32 public immutable feedId;
    uint256 public immutable maxStaleness;
    bool public immutable inverse;
    uint8 public immutable decimals;

    constructor(address _pyth, address _base, address _quote, bytes32 _feedId, uint256 _maxStaleness, bool _inverse) {
        pyth = IPyth(_pyth);
        base = _base;
        quote = _quote;
        feedId = _feedId;
        maxStaleness = _maxStaleness;
        inverse = _inverse;
        decimals = ERC20(_inverse ? _quote : _base).decimals();
    }

    function getQuote(uint256 inAmount, address _base, address _quote) external view override returns (uint256) {
        PythStructs.Price memory priceStruct = _fetchPriceStruct(_base, _quote);
        uint32 exponent = uint32(priceStruct.expo) + decimals;

        if (inverse) return inAmount * 10 ** exponent / uint64(priceStruct.price);
        else return inAmount * uint64(priceStruct.price) / 10 ** exponent;
    }

    function getQuotes(uint256 inAmount, address _base, address _quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        PythStructs.Price memory priceStruct = _fetchPriceStruct(_base, _quote);
        uint32 exponent = uint32(priceStruct.expo) + decimals;

        uint64 bidPrice = uint64(priceStruct.price) - priceStruct.conf;
        uint64 askPrice = uint64(priceStruct.price) + priceStruct.conf;
        if (inverse) {
            return (inAmount * 10 ** exponent / askPrice, inAmount * 10 ** exponent / bidPrice);
        } else {
            return (inAmount * bidPrice / 10 ** exponent, inAmount * askPrice / 10 ** exponent);
        }
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.PythOracle(maxStaleness);
    }

    function _fetchPriceStruct(address _base, address _quote) internal view returns (PythStructs.Price memory) {
        if (base != _base || quote != _quote) revert Errors.EOracle_NotSupported(_base, _quote);
        PythStructs.Price memory priceStruct = pyth.getPriceNoOlderThan(feedId, maxStaleness);
        _sanityCheckPriceStruct(priceStruct);
        return priceStruct;
    }

    function _sanityCheckPriceStruct(PythStructs.Price memory price) internal pure {
        if (price.price <= 0) {
            revert Errors.Pyth_InvalidPrice(price.price);
        }

        if (price.conf > uint64(type(int64).max) || int64(price.conf) > price.price) {
            revert Errors.Pyth_InvalidConfidenceInterval(price.price, price.conf);
        }

        if (price.expo > 32 || price.expo < -32) {
            revert Errors.Pyth_InvalidExponent(price.expo);
        }
    }
}
