// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pyth-sdk-solidity/PythStructs.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";

contract ImmutablePythOracle {
    IPyth public immutable pyth;
    uint256 public immutable maxStaleness;

    struct PythConfig {
        bytes32 feedId;
        uint8 decimals;
    }

    /// @dev all Pyth crypto feeds are USD-denominated
    mapping(address token => PythConfig) public configs;

    error ArityMismatch(uint256 arityA, uint256 arityB);
    error ConfigAlreadyExists(address token);
    error ConfigDoesNotExist(address token);
    error InvalidConfidenceInterval(int64 price, uint64 conf);
    error InvalidExponent(int32 expo);
    error InvalidPrice(int64 price);

    constructor(address _pyth, uint256 _maxStaleness, address[] memory tokens, bytes32[] memory feedIds) {
        pyth = IPyth(_pyth);
        maxStaleness = _maxStaleness;

        if (tokens.length != feedIds.length) revert ArityMismatch(tokens.length, feedIds.length);
        uint256 length = tokens.length;

        for (uint256 i = 0; i < length;) {
            _initConfig(tokens[i], feedIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    function canQuote(uint256, address base, address quote) external view returns (bool) {
        bytes32 baseFeedId = configs[base].feedId;
        if (baseFeedId == 0) return false;
        bytes32 quoteFeedId = configs[quote].feedId;
        if (quoteFeedId == 0) return false;

        PythStructs.Price memory basePriceStruct;
        try pyth.getPriceNoOlderThan(baseFeedId, maxStaleness) returns (PythStructs.Price memory _priceStruct) {
            basePriceStruct = _priceStruct;
        } catch {
            return false;
        }

        PythStructs.Price memory quotePriceStruct;
        try pyth.getPriceNoOlderThan(baseFeedId, maxStaleness) returns (PythStructs.Price memory _priceStruct) {
            quotePriceStruct = _priceStruct;
        } catch {
            return false;
        }

        // todo: more checks
        return true;
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256) {
        PythStructs.Price memory basePriceStruct = _fetchPriceStruct(base);
        PythStructs.Price memory quotePriceStruct = _fetchPriceStruct(quote);

        uint8 baseDecimals = configs[base].decimals;
        uint8 quoteDecimals = configs[quote].decimals;

        return _calculatePrice(inAmount, basePriceStruct, quotePriceStruct, baseDecimals, quoteDecimals);
    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256, uint256) {
        PythStructs.Price memory basePriceStruct = _fetchPriceStruct(base);
        PythStructs.Price memory quotePriceStruct = _fetchPriceStruct(quote);

        uint8 baseDecimals = configs[base].decimals;
        uint8 quoteDecimals = configs[quote].decimals;

        return _calculateSpreadPrice(inAmount, basePriceStruct, quotePriceStruct, baseDecimals, quoteDecimals);
    }

    function _initConfig(address token, bytes32 feedId) internal {
        uint8 decimals = ERC20(token).decimals();
        configs[token] = PythConfig(feedId, decimals);
    }

    function _fetchPriceStruct(address token) internal view returns (PythStructs.Price memory) {
        bytes32 feedId = configs[token].feedId;
        if (feedId == 0) revert ConfigDoesNotExist(token);
        return pyth.getPriceNoOlderThan(feedId, maxStaleness);
    }

    function _sanityCheckPriceStruct(PythStructs.Price memory price) internal pure {
        if (price.price <= 0) {
            revert InvalidPrice(price.price);
        }

        if (price.conf > uint64(type(int64).max) || int64(price.conf) > price.price) {
            revert InvalidConfidenceInterval(price.price, price.conf);
        }

        if (price.expo > 0 || price.expo < -255) {
            revert InvalidExponent(price.expo);
        }
    }

    function _calculatePrice(
        uint256 inAmount,
        PythStructs.Price memory basePrice,
        PythStructs.Price memory quotePrice,
        uint8 baseDecimals,
        uint8 quoteDecimals
    ) internal pure returns (uint256) {
        _sanityCheckPriceStruct(basePrice);
        _sanityCheckPriceStruct(quotePrice);

        int8 netDecimals = int8(basePrice.expo) - int8(quotePrice.expo) + int8(quoteDecimals) - int8(baseDecimals);

        if (netDecimals > 0) {
            return (inAmount * uint256(uint64(basePrice.price)) * 10 ** uint8(netDecimals))
                / uint256(uint64(quotePrice.price));
        } else {
            return (inAmount * uint256(uint64(basePrice.price)))
                / (uint256(uint64(quotePrice.price)) * 10 ** uint8(-netDecimals));
        }
    }

    function _calculateSpreadPrice(
        uint256 inAmount,
        PythStructs.Price memory basePrice,
        PythStructs.Price memory quotePrice,
        uint8 baseDecimals,
        uint8 quoteDecimals
    ) internal pure returns (uint256, uint256) {
        _sanityCheckPriceStruct(basePrice);
        _sanityCheckPriceStruct(quotePrice);

        int8 netDecimals = int8(basePrice.expo) - int8(quotePrice.expo) + int8(quoteDecimals) - int8(baseDecimals);
        (uint256 baseBidPrice, uint256 baseAskPrice) = _getBidAsk(basePrice);
        (uint256 quoteBidPrice, uint256 quoteAskPrice) = _getBidAsk(quotePrice);

        if (netDecimals > 0) {
            // fix: stack too deep :(
            // uint256 bid = (inAmount * baseBidPrice * 10 ** uint8(netDecimals)) / quoteBidPrice;
            // uint256 ask = (inAmount * baseAskPrice * 10 ** uint8(netDecimals)) / quoteAskPrice;
            return (
                (inAmount * baseBidPrice * 10 ** uint8(netDecimals)) / quoteBidPrice,
                (inAmount * baseAskPrice * 10 ** uint8(netDecimals)) / quoteAskPrice
            );
        } else {
            uint256 bid = (inAmount * baseBidPrice) / (quoteBidPrice * 10 ** uint8(-netDecimals));
            uint256 ask = (inAmount * baseAskPrice) / (quoteAskPrice * 10 ** uint8(-netDecimals));
            return (bid, ask);
        }
    }

    /// @dev MUST call _sanityCheckPriceStruct beforehand, otherwise over/underflows may occur
    function _getBidAsk(PythStructs.Price memory priceStruct)
        internal
        pure
        returns (uint256 bidPrice, uint256 askPrice)
    {
        int64 price = priceStruct.price;
        uint64 conf = priceStruct.conf;
        assembly {
            bidPrice := sub(price, conf)
            askPrice := add(price, conf)
        }
    }
}
