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
    uint8 public immutable baseDecimals;
    uint8 public immutable quoteDecimals;

    constructor(address _pyth, address _base, address _quote, bytes32 _feedId, uint256 _maxStaleness, bool _inverse) {
        pyth = IPyth(_pyth);
        base = _base;
        quote = _quote;
        feedId = _feedId;
        maxStaleness = _maxStaleness;
        inverse = _inverse;
        baseDecimals = ERC20(_base).decimals();
        quoteDecimals = ERC20(_quote).decimals();
    }

    function updatePrice(bytes[] calldata updateData) external payable {
        IPyth(pyth).updatePriceFeeds{value: msg.value}(updateData);
    }

    function getQuote(uint256 inAmount, address _base, address _quote) external view override returns (uint256) {
        PythStructs.Price memory priceStruct = _fetchPriceStruct(_base, _quote);

        if (inverse) {
            int32 exponent = priceStruct.expo - int8(quoteDecimals) + int8(baseDecimals);
            if (exponent > 0) {
                return inAmount / (uint64(priceStruct.price) * 10 ** uint32(exponent));
            } else {
                return inAmount * 10 ** uint32(-exponent) / uint64(priceStruct.price);
            }
        } else {
            int32 exponent = priceStruct.expo + int8(quoteDecimals) - int8(baseDecimals);
            if (exponent > 0) {
                return inAmount * uint64(priceStruct.price) * 10 ** uint32(exponent);
            } else {
                return inAmount * uint64(priceStruct.price) / 10 ** uint32(-exponent);
            }
        }
    }

    function getQuotes(uint256 inAmount, address _base, address _quote)
        external
        view
        override
        returns (uint256, uint256)
    {
        PythStructs.Price memory priceStruct = _fetchPriceStruct(_base, _quote);
        uint64 bidPrice = uint64(priceStruct.price - int64(priceStruct.conf));
        uint64 askPrice = uint64(priceStruct.price + int64(priceStruct.conf));

        if (inverse) {
            int32 exponent = priceStruct.expo - int8(quoteDecimals) + int8(baseDecimals);
            if (exponent > 0) {
                return (inAmount / (askPrice * 10 ** uint32(exponent)), inAmount / (bidPrice * 10 ** uint32(exponent)));
            } else {
                return (inAmount * 10 ** uint32(-exponent) / askPrice, inAmount * 10 ** uint32(-exponent) / bidPrice);
            }
        } else {
            int32 exponent = priceStruct.expo + int8(quoteDecimals) - int8(baseDecimals);
            if (exponent > 0) {
                return (inAmount * bidPrice * 10 ** uint32(exponent), inAmount * askPrice * 10 ** uint32(exponent));
            } else {
                return (inAmount * bidPrice / 10 ** uint32(-exponent), inAmount * askPrice / 10 ** uint32(-exponent));
            }
        }
    }

    function description() external view returns (OracleDescription.Description memory) {
        return OracleDescription.PythOracle(maxStaleness);
    }

    function _fetchPriceStruct(address _base, address _quote) internal view returns (PythStructs.Price memory) {
        if (base != _base || quote != _quote) revert Errors.EOracle_NotSupported(_base, _quote);
        PythStructs.Price memory p = pyth.getPriceNoOlderThan(feedId, maxStaleness);
        if (p.price <= 0) {
            revert Errors.Pyth_InvalidPrice(p.price);
        }

        if (p.conf > uint64(type(int64).max) || int64(p.conf) > p.price) {
            revert Errors.Pyth_InvalidConfidenceInterval(p.price, p.conf);
        }

        if (p.expo > 32 || p.expo < -32) {
            revert Errors.Pyth_InvalidExponent(p.expo);
        }
        return p;
    }
}
