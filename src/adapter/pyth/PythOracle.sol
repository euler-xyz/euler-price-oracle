// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.22;

import {IPyth} from "@pyth-sdk-solidity/IPyth.sol";
import {PythStructs} from "@pyth-sdk-solidity/PythStructs.sol";
import {ERC20} from "@solady/tokens/ERC20.sol";
import {IOracle} from "src/interfaces/IOracle.sol";

abstract contract PythOracle is IOracle {
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

    function getQuote(uint256 inAmount, address base, address quote) external view virtual returns (uint256);
    function getQuotes(uint256 inAmount, address base, address quote)
        external
        view
        virtual
        returns (uint256, uint256);

    function _initConfig(address token, bytes32 feedId) internal {
        uint8 decimals = ERC20(token).decimals();
        configs[token] = PythConfig(feedId, decimals);
    }

    function _fetchPriceStruct(address token) internal view returns (PythStructs.Price memory) {
        bytes32 feedId = configs[token].feedId;
        if (feedId == 0) revert ConfigDoesNotExist(token);
        return pyth.getPriceNoOlderThan(feedId, maxStaleness);
    }

    function _fetchEMAPriceStruct(address token) internal view returns (PythStructs.Price memory) {
        bytes32 feedId = configs[token].feedId;
        if (feedId == 0) revert ConfigDoesNotExist(token);
        return pyth.getEmaPriceNoOlderThan(feedId, maxStaleness);
    }

    function _combinePrices(
        uint256 inAmount,
        PythStructs.Price memory baseStruct,
        PythStructs.Price memory quoteStruct,
        uint8 baseDecimals,
        uint8 quoteDecimals
    ) internal pure returns (uint256 result) {
        _sanityCheckPriceStruct(baseStruct);
        _sanityCheckPriceStruct(quoteStruct);

        int256 netDecimals = _calculateNetDecimals(baseStruct.expo, quoteStruct.expo, baseDecimals, quoteDecimals);

        return _calculatePrice(inAmount, baseStruct.price, quoteStruct.price, netDecimals);
    }

    function _combinePricesWithSpread(
        uint256 inAmount,
        PythStructs.Price memory baseStruct,
        PythStructs.Price memory quoteStruct,
        uint8 baseDecimals,
        uint8 quoteDecimals
    ) internal pure returns (uint256, uint256) {
        _sanityCheckPriceStruct(baseStruct);
        _sanityCheckPriceStruct(quoteStruct);

        int256 netDecimals = _calculateNetDecimals(baseStruct.expo, quoteStruct.expo, baseDecimals, quoteDecimals);
        (int64 baseBidPrice, int64 baseAskPrice) = _getBidAsk(baseStruct);
        (int64 quoteBidPrice, int64 quoteAskPrice) = _getBidAsk(quoteStruct);

        uint256 bid = _calculatePrice(inAmount, baseBidPrice, quoteBidPrice, netDecimals);
        uint256 ask = _calculatePrice(inAmount, baseAskPrice, quoteAskPrice, netDecimals);
        return (bid, ask);
    }

    function _calculatePrice(uint256 inAmount, int64 basePrice, int64 quotePrice, int256 netDecimals)
        internal
        pure
        returns (uint256 result)
    {
        // uint256 scalingFactor = netDecimals > 0 ? 10 ** uint256(netDecimals) : 10 ** uint256(-netDecimals);
        uint256 scalingFactor;
        assembly ("memory-safe") {
            let absDecimals := xor(sub(0, shr(255, netDecimals)), add(sub(0, shr(255, netDecimals)), netDecimals))
            // scalingFactor := 10^|netDecimals|
            scalingFactor := exp(10, absDecimals)
        }

        if (netDecimals > 0) {
            // return (inAmount * uint256(uint64(basePrice)) * scalingFactor) / uint256(uint64(quotePrice));
            assembly ("memory-safe") {
                result := mul(inAmount, basePrice)
                result := mul(result, scalingFactor)
                result := div(result, quotePrice)
            }
        } else {
            // return (inAmount * uint256(uint64(basePrice))) / (uint256(uint64(quotePrice)) * scalingFactor);
            assembly ("memory-safe") {
                result := mul(inAmount, basePrice)
                let denom := mul(quotePrice, scalingFactor)
                result := div(result, denom)
            }
        }
    }

    /// @dev MUST call _sanityCheckPriceStruct beforehand, otherwise over/underflows may occur
    function _getBidAsk(PythStructs.Price memory priceStruct) internal pure returns (int64 bidPrice, int64 askPrice) {
        int64 price = priceStruct.price;
        uint64 conf = priceStruct.conf;
        assembly {
            bidPrice := sub(price, conf)
            askPrice := add(price, conf)
        }
    }

    /// @notice Calculates the net scaling decimals needed when diving base by quote
    /// @dev basePriceExponent - quotePriceExponent + quoteDecimals - baseDecimals
    function _calculateNetDecimals(
        int32 basePriceExponent,
        int32 quotePriceExponent,
        uint8 baseDecimals,
        uint8 quoteDecimals
    ) internal pure returns (int256 netDecimals) {
        assembly ("memory-safe") {
            netDecimals := sub(basePriceExponent, quotePriceExponent)
            netDecimals := add(netDecimals, quoteDecimals)
            netDecimals := sub(netDecimals, baseDecimals)
        }
    }

    function _sanityCheckPriceStruct(PythStructs.Price memory price) internal pure {
        if (price.price <= 0) {
            revert InvalidPrice(price.price);
        }

        if (price.conf > uint64(type(int64).max) || int64(price.conf) > price.price) {
            revert InvalidConfidenceInterval(price.price, price.conf);
        }

        if (price.expo > 255 || price.expo < -255) {
            revert InvalidExponent(price.expo);
        }
    }
}
